require 'sketchup.rb'

module MSketchyPhysics3

def self.setDefaultPhysicsSettings
    model = Sketchup.active_model
    model.set_attribute('SPSETTINGS', 'defaultobjectdensity', '0.2')
    model.set_attribute('SPSETTINGS', 'worldscale', '9.0')
    model.set_attribute('SPSETTINGS', 'gravity', '1.0')
    model.set_attribute('SPSETTINGS', 'framerate', 3)
    #model.set_attribute('SPSETTINGS', 'water', 1)
end

def self.getNewtonVersion
    MSketchyPhysics3::NewtonServer.newtonWorldGetVersion * 0.01
end

=begin
class SP3xCommonContext
    # Security
    class Kernel
    end
    class Dir
    end
    class File
    end
    class IO
    end
    class Thread
    end
    class Process
    end
end # class SP3xCommonContext
=end

class SketchyPhysicsClient

    def extractScaleFromGroup(group)
        tra = group.transformation
        Geom::Transformation.scaling(
          X_AXIS.transform(tra).length,
          Y_AXIS.transform(tra).length,
          Z_AXIS.transform(tra).length
        )
    end


    def findParentInstance(ci)
        MSketchyPhysics3.get_definition(ci).instances.each { |di|
            return di if ci == di
        }
        nil
    end

    def resetAxis(ent)
        SketchyPhysicsClient.resetAxis(ent)
    end

    @@origAxis = {}

    def self.resetAxis(ent)
        if ent.is_a?(Sketchup::ComponentDefinition)
            cd = ent
        else
            #~ ent.make_unique
            cd = MSketchyPhysics3.get_definition(ent)
        end
        realBounds = Geom::BoundingBox.new
        # Calculate the real bounding box of the entities in the component.
        cd.entities.each { |de| realBounds.add(de.bounds) }
        # Desired center.
        center = Geom::Point3d.new(0,0,0)
        # If not already centred.
        if realBounds.center != center
            # Save original axis.
            c = realBounds.center
            orig = Geom::Point3d.new(-c.x, -c.y, -c.z)
            @@origAxis[cd.entityID] = orig
            # Transform all the entities to be around the new center.
            cd.entities.transform_entities(Geom::Transformation.new(center-realBounds.center), cd.entities.to_a)
            cd.invalidate_bounds if cd.respond_to?(:invalidate_bounds)
            # Move each instance of this component to account for the entities moving inside the component.
            cd.instances.each { |ci|
                newCenter = realBounds.center.transform(ci.transformation)
                matrix = ci.transformation.to_a
                matrix[12..14] = newCenter.to_a
                ci.move! Geom::Transformation.new(matrix)
            }
        end
    end

    #~ def copyAndKick(grp, pos = nil, kick = nil)
        #~ kick= [0, 0, kick.to_f] unless kick.is_a?(Array)

        #~ grp=Sketchup.active_model.add_instance(ogrp.definition,ogrp.transformation)

        #~ @tempObjects.push(grp)
        #~ grp.material=ogrp.material
        #~ grp.name="__copy"
        #~ grp.set_attribute( 'SPOBJ', 'shape',ogrp.get_attribute( 'SPOBJ', 'shape', nil))
        #~ collisions=dumpGroupCollision(grp,0,extractScaleFromGroup(grp)*(grp.transformation.inverse))

        #~ if(!collisions.empty?)
            #~ if(pos!=nil)
                #~ xform=Geom::Transformation.new(pos)
            #~ else
                #~ xform=nil
            #~ end
            #~ body=createBodyFromCollision(grp,collisions,xform);

            #~  MSketchyPhysics3::NewtonServer.addImpulse(body,kick.to_a.pack('f*'),grp.transformation.origin.to_a.pack('f*'))
        #~ end


            #~ if(grp.valid?)
                #~ newgrp=emitGroup(grp,value)
                #~ if(newgrp!=nil) #sucessfully copied?
                    #~ rate=grp.get_attribute('SPOBJ',"emitterrate",10)
                    #~ grp.set_attribute('SPOBJ',"lastemissionframe",@@frame)
                    #~ lifetime=grp.get_attribute('SPOBJ',"lifetime",0).to_f
                    #~ if(lifetime!=nil && lifetime>0)
                        #~ #puts "dying obj"+lifetime.to_s
                        #~ #newgrp.set_attribute('SPOBJ',"diesatframe",nil)
                        #~ @dyingObjects.push([newgrp,@@frame+lifetime])
                    #~ end

                #~ end
            #~ end

    #~ end

    def destroyTempObject(grp)
        address = grp.get_attribute('SPOBJ', 'body', 0).to_i
        return if address.zero?
        body_ptr = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(address) : Fiddle::Pointer.new(address)
        MSketchyPhysics3::NewtonServer.destroyBody(body_ptr)
    end

    def emitGroup(grp, xform = nil, strength = 15, lifetime = nil, density = nil, cc = false)
        if strength.is_a?(Numeric)
            kick = grp.transformation.zaxis
            kick.length = strength
        else
            kick = Geom::Vector3d.new(strength.to_a)
        end
        lifetime = grp.get_attribute('SPOBJ', 'lifetime', 0) unless lifetime
        newgrp = copyBody(grp, xform, lifetime, density)
        return unless newgrp
        pushBody(newgrp, kick)
        if cc
          body_ptr = findBodyFromInstance(newgrp)
          MSketchyPhysics3::NewtonServer.newtonBodySetContinuousCollisionMode(body_ptr, 1)
        end
        grp.set_attribute('SPOBJ', 'lastemissionframe', @@frame)
        @emitted[grp] ||= []
        @emitted[grp] << newgrp
        newgrp
    end

    def getEmitter(grp)
      @emitted.each { |k, v|
        return k if v.include?(grp)
      }
      nil
    end

    def setLifetime(grp, lifetime)
        return unless grp.is_a?(Sketchup::Group) || grp.is_a?(Sketchup::ComponentInstance)
        @dyingObjects.each { |data|
          if data[0] == grp
            data[1] = @@frame + lifetime.to_i
            data[2] = @@frame
            data[3] = lifetime.to_i
            return lifetime.to_i
          end
        }
        @dyingObjects << [grp, @@frame + lifetime.to_i, @@frame, lifetime.to_i]
        lifetime.to_i
    end

    def getLifetime(grp)
      @dyingObjects.each { |group, life_end, life_start, life_time|
        return life_time if group == grp
      }
      return 0
    end

    def getLifeStart(grp)
      @dyingObjects.each { |group, life_end, life_start, life_time|
        return life_start if group == grp
      }
      return 0
    end

    def getLifeEnd(grp)
      @dyingObjects.each { |group, life_end, life_start, life_time|
        return life_end if group == grp
      }
      return 0
    end

    def newBody(grp, xform = nil, lifetime = 0)
        return unless grp.is_a?(Sketchup::Group) || grp.is_a?(Sketchup::ComponentInstance)
        xform = xform ? Geom::Transformation.new(xform) : grp.transformation
        collisions = dumpGroupCollision(grp, 0, extractScaleFromGroup(grp)*(grp.transformation.inverse))
        return if collisions.empty?
        body = createBodyFromCollision(grp, collisions)
        if lifetime.is_a?(Numeric) and lifetime.to_i > 0
            setLifetime(grp, lifetime.to_i)
        end
        @tempObjects << grp
        grp
    end

    def copyBody(grp, xform = nil, lifetime = 0, density = nil)
        return unless grp.is_a?(Sketchup::Group) || grp.is_a?(Sketchup::ComponentInstance)
        #~ address = grp.get_attribute('SPOBJ', 'body', 0).to_i
        #~ return if address.zero?
        xform = xform ? Geom::Transformation.new(xform) : grp.transformation
        newgrp = Sketchup.active_model.entities.add_instance(MSketchyPhysics3.get_definition(grp), xform)
        newgrp.material = grp.material
        #~ newgrp.make_unique
        attrib = 'shape'
        shape = grp.get_attribute('SPOBJ', attrib, nil)
        unless shape
          attrib = 'advancedShape'
          shape = grp.get_attribute('SPOBJ', attrib, nil)
        end
        newgrp.set_attribute('SPOBJ', attrib, shape) if shape
        unless density.is_a?(Numeric)
            default = Sketchup.active_model.get_attribute('SPSETTINGS', 'defaultobjectdensity', 0.2).to_f
            density = grp.get_attribute('SPOBJ', 'density', default)
            newgrp.set_attribute('SPOBJ', 'density', density)
        end
        collisions = dumpGroupCollision(newgrp, 0, extractScaleFromGroup(newgrp)*(xform.inverse))
        if collisions.empty?
            newgrp.erase! if newgrp.valid?
            return
        end
        newbody = createBodyFromCollision(newgrp, collisions)
        if lifetime.is_a?(Numeric) and lifetime.to_i > 0
            setLifetime(newgrp, lifetime.to_i)
        end
        @tempObjects << newgrp
        newgrp
    end

    def pushBody(grp, strength)
        return unless strength
        return unless grp.is_a?(Sketchup::Group) || grp.is_a?(Sketchup::ComponentInstance)
        address = grp.get_attribute('SPOBJ', 'body', 0).to_i
        return if address.zero?
        body_ptr = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(address) : Fiddle::Pointer.new(address)
        if strength.is_a?(Numeric)
            return if strength.zero?
            kick = grp.transformation.zaxis
            kick.length = strength
        else
            kick = Geom::Vector3d.new(strength.to_a)
        end

        buffer = RUBY_VERSION =~ /1.8/ ? (0.chr*64).to_ptr : 0.chr*64
        MSketchyPhysics3::NewtonServer.newtonBodyGetMatrix(body_ptr, buffer)
        matrix = RUBY_VERSION =~ /1.8/ ? buffer.to_a('F16') : buffer.unpack('F*')
        tra = Geom::Transformation.new(matrix)

        buffer = RUBY_VERSION =~ /1.8/ ? (0.chr*12).to_ptr : 0.chr*12
        MSketchyPhysics3::NewtonServer.newtonBodyGetCentreOfMass(body_ptr, buffer)
        centre = RUBY_VERSION =~ /1.8/ ? buffer.to_a('F3') : buffer.unpack('F*')
        centre.transform!(tra)

        #MSketchyPhysics3::NewtonServer.addImpulse(body_ptr, kick.to_a.pack('f*'), grp.transformation.origin.to_a.pack('f*'))
        MSketchyPhysics3::NewtonServer.newtonAddBodyImpulse(body_ptr, kick.to_a.pack('f*'), centre.pack('f*'))
    end

    def dumpCollision
        Sketchup.active_model.entities.each { |ent|
            next unless ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
            if ent.attribute_dictionary('SPWATERPLANE')
                density = ent.get_attribute('SPWATERPLANE', 'density', 1.0)
                linearViscosity = ent.get_attribute('SPWATERPLANE', 'linearViscosity', 1.0)
                angularViscosity = ent.get_attribute('SPWATERPLANE', 'angularViscosity', 1.0)
                current = ent.get_attribute('SPWATERPLANE', 'current', [0,0,0])
                xform = ent.transformation
                plane = Geom.fit_plane_to_points(xform.origin, xform.origin+xform.xaxis, xform.origin+xform.yaxis)
                MSketchyPhysics3::NewtonServer.setupBouyancy(plane.to_a.pack('f*'),
                    [0.0+current[0], 0.0+current[1], -9.8+current[2]].pack('f*'),
                    [density, linearViscosity, angularViscosity].pack('f*'))
            end
            unless ent.get_attribute('SPOBJ', 'ignore', false)
                #~ resetAxis(ent)
                tra = ent.transformation
                collisions = dumpGroupCollision(ent, 0, extractScaleFromGroup(ent)*tra.inverse)
                createBodyFromCollision(ent, collisions) unless collisions.empty?
            end
            return false unless SketchyPhysicsClient.active?
        }
        true
    end

    def createBodyFromCollision(group, collisions, new_xform = nil)
        id = @DynamicObjectList.size
        bDynamic = 1 # group.get_attribute('SPOBJ', 'static', false) ? 0 : 1
        collisions.flatten!
        xform = new_xform ? Geom::Transformation.new(new_xform) : group.transformation
        # Figure out the scaling of the xform.
        flip = (xform.xaxis*xform.yaxis)%xform.zaxis < 0 ? -1 : 1
        scale = [
          X_AXIS.transform(xform).length,
          Z_AXIS.transform(xform).length,
          Z_AXIS.transform(xform).length
        ]
        # Find the real size of the bounding box and offset to center.
        bb = MSketchyPhysics3.get_definition(group).bounds
        size = [bb.width*scale[0], bb.height*scale[1], bb.depth*scale[2]]
        default = Sketchup.active_model.get_attribute('SPSETTINGS', 'defaultobjectdensity', 0.2).to_f
        density = group.get_attribute('SPOBJ', 'density', default).to_f
        density = 0.2 if density <= 0
        body = MSketchyPhysics3::NewtonServer.createBody(
            id, collisions.pack('L*'),
            collisions.size, bDynamic, size.pack('f*'),
            xform.to_a.pack('f*'), density
        )
        # Save body in obj for later reference.
        group.set_attribute('SPOBJ', 'body', body.to_i)
        scaling = extractScaleFromGroup(group).to_a
        for i in 8..10; scaling[i] *= flip end
        group.set_attribute('SPOBJ', 'savedScale', scaling)
        if group.get_attribute('SPOBJ', 'showgeometry', false)
            showCollision(group, body)
        end
        updateEmbeddedGeometry(group, body)
        jnames = JointConnectionTool.getParentJointNames(group)

        @AllJointChildren.push(group) unless jnames.empty?

        # Set freeze if needed
        s = group.get_attribute('SPOBJ', 'frozen', false)
        MSketchyPhysics3::NewtonServer.bodySetFreeze(body, s ? 1 : 0)
        if group.get_attribute('SPOBJ', 'noautofreeze', false)
            # Hack! to force unfreeze of body
            MSketchyPhysics3::NewtonServer.setBodyMagnetic(body, 1)
            MSketchyPhysics3::NewtonServer.setBodyMagnetic(body, 0)
        end
        if (group.get_attribute('SPOBJ', 'magnet', false) &&
            group.get_attribute('SPJOINT', 'type', nil) == nil)
            #strength = group.get_attribute('SPOBJ', 'strength', 0.0)
            force = MSketchyPhysics3::NewtonServer.addForce(body, 0.0)
            group.set_attribute('SPOBJ', '__force', force.to_i)
            @allForces << group
        end
        if (group.get_attribute('SPOBJ', 'thruster', false) &&
            group.get_attribute('SPJOINT', 'type', nil) == nil)
            # Hack! to force unfreeze of body
            MSketchyPhysics3::NewtonServer.setBodyMagnetic(body, 1)
            MSketchyPhysics3::NewtonServer.setBodyMagnetic(body, 0)
            @allThrusters << group
        end
        if (group.get_attribute('SPOBJ', 'tickable', false) &&
            group.get_attribute('SPJOINT', 'type', nil) == nil)
            @allTickables << group
            # Ensure it ticks right away.
            group.set_attribute('SPOBJ', 'nexttickframe', 0)
        end
        if group.get_attribute('SPOBJ', 'touchable', false)
            MSketchyPhysics3::NewtonServer.bodySetMaterial(body, 1)
            MSketchyPhysics3::NewtonServer.setBodyCollideCallback(body, MSketchyPhysics3::NewtonServer::COLLIDE_CALLBACK)
            group.set_attribute('SPOBJ', 'lasttouchframe', 0)
        end
        if (group.get_attribute('SPOBJ', 'materialid', false) &&
            group.get_attribute('SPJOINT', 'type', nil) == nil)
            matid = group.get_attribute('SPOBJ', 'materialid', 0)
            MSketchyPhysics3::NewtonServer.bodySetMaterial(body, matid.to_i)
        end
        if (group.get_attribute('SPOBJ', 'emitter', false) &&
            group.get_attribute('SPJOINT', 'type', nil) == nil)
            group.set_attribute('SPOBJ', 'lastemissionframe', 0)
            @allEmitters << group
        end
        # Used by touchable etc.
        @bodyToGroup[body.to_i] = group
        # Use body bounds center as centre of mass for most shapes.
        center = MSketchyPhysics3.get_definition(group).bounds.center.transform(extractScaleFromGroup(group))
        center.z *= flip
        MSketchyPhysics3::NewtonServer.setBodyCenterOfMass(body, center.to_a.pack('f*'))
        # Used in update to lookup object.
        @DynamicObjectList << group
        @DynamicObjectResetPositions << group.transformation
        # Clear some temporary variables.
        group.set_attribute('SPOBJ', '__lookAtJoint', nil)
        # Create body
        shape = group.get_attribute('SPOBJ', 'shape', nil)
        shape = group.get_attribute('SPOBJ', 'advancedShape', nil) unless shape
        body_context = @simulationContext.createBody(group, body, shape, density)
        return unless SketchyPhysicsClient.active?
        body_context.static = group.get_attribute('SPOBJ', 'static', false)
        body_context.nocollision = group.get_attribute('SPOBJ', 'nocollison', false)
        body_context.magnetic = group.get_attribute('SPOBJ', 'magnetic', false)
        # Save position of all objects for reset.
        @DynamicObjectBodyRef << body
        body
    end

    def dumpGroupCollision(group, depth, parent_xform)
        return [] if group.get_attribute('SPOBJ', 'ignore', false)
        tra = group.transformation
        xform = parent_xform*tra
        shape = group.get_attribute('SPOBJ', 'shape', nil)
        shape = group.get_attribute('SPOBJ', 'advancedShape', nil) unless shape
        valid_shapes = %w(staticmesh staticmesh2 compound2 convexhull convexhull2 box sphere cone cylinder chamfer capsule)
        unless valid_shapes.include?(shape)
          shape = nil
          group.delete_attribute('SPOBJ', 'shape')
          group.delete_attribute('SPOBJ', 'advancedShape')
        end
        @AllCollisionEntities << group
        unless group.parent.is_a?(Sketchup::Model)
          if %w(staticmesh staticmesh2 compound2).include?(shape)
            shape = nil
            group.delete_attribute('SPOBJ', 'shape')
            group.delete_attribute('SPOBJ', 'advancedShape')
          end
          group.delete_attribute('SPOBJ', 'staticmesh')
        end
        if shape == 'staticmesh' || group.get_attribute('SPOBJ', 'staticmesh', false)
          return [createStaticMeshCollision(group)]
        elsif shape == 'staticmesh2'
          return [createStaticMesh2Collision(group)]
        elsif shape == 'compound2'
          return createCompound2Collision(group, group.transformation, nil)
        elsif shape == 'convexhull' || shape == 'convexhull2'
          col = createConvexHullCollision(group, xform, shape == 'convexhull2')
          return col ? [col] : []
        end
        return [createDefaultCollision(group, group.transformation, nil)]
    end

    # Get vertices from all faces of a group/component.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] ent
    # @param [Boolean] recursive Whether to include all the child groups and
    #   components.
    # @param [Boolean] transform Whether to give points in global coordinates.
    # @return [Array<Array<Numeric>>] An array of points.
    def get_vertices_from_faces(ent, recursive = true, transform = true)
      pts = []
      MSketchyPhysics3.get_entities(ent).each { |e|
        if((e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)) && recursive &&
           !e.get_attribute('SPOBJ', 'ignore', false) && !e.attribute_dictionary('SPJOINT', nil))
          pts.concat get_vertices_from_faces(e, true, true)
          next
        end
        next unless e.is_a?(Sketchup::Face)
        e.vertices.each { |v| pts << v.position.to_a }
      }
      if transform
        tra = ent.transformation
        pts.each { |pt| pt.transform!(tra) }
      end
      pts.uniq!
      pts
    end

    # Get all polygons from all faces of a group/component.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] ent
    # @param [Boolean] recursive Whether to include all the child groups and
    #   components.
    # @param [Boolean] transform Whether to give points in global coordinates.
    # @return [Array<Array<Array<Numeric>>>] An array of polygons. Each polygon
    #   represents an array of three points (a triplex). Each point represents and array on numbers.
    def get_polygons_from_faces(ent, recursive = true, transform = true)
      faces = []
      MSketchyPhysics3.get_entities(ent).each { |e|
        if((e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)) && recursive &&
           !e.get_attribute('SPOBJ', 'ignore', false) && !e.attribute_dictionary('SPJOINT', false))
          faces.concat get_polygons_from_faces(e, true, true)
          next
        end
        next unless e.is_a?(Sketchup::Face)
        e.mesh.polygons.each_index{ |i|
          pts = []
          e.mesh.polygon_points_at(i+1).each { |pt| pts << pt.to_a }
          faces << pts
        }
      }
      if transform
        tra = ent.transformation
        faces.each { |face|
          face.each { |pt| pt.transform!(tra) }
        }
      end
      faces
    end

    def createConvexHullCollision(group, xform, recursive = false)
      verts = get_vertices_from_faces(group, recursive, false)
      return if verts.size < 4
      tra = group.transformation
      flip = (tra.xaxis*tra.yaxis)%tra.zaxis < 0 ? -1 : 1
      scale = [
        X_AXIS.transform(tra).length,
        Y_AXIS.transform(tra).length,
        Z_AXIS.transform(tra).length * flip
      ]
      verts.each { |pt|
        for i in 0..2; pt[i] *= scale[i] end
      }
      noscale = Geom::Transformation.new(xform.xaxis, xform.yaxis, xform.zaxis, xform.origin)
      vcloud = [verts.size] + verts.flatten
      bb = MSketchyPhysics3.get_definition(group).bounds
      size = [bb.width*scale[0], bb.height*scale[1], bb.depth*scale[2]]
      col = MSketchyPhysics3::NewtonServer.createCollision(
        'convexhull',
        size.pack('f*'),
        noscale.to_a.pack('f*'),
        vcloud.pack('f*')
      )
      col.to_i
    end

    def createDefaultCollision(group, parent_xform, xform = nil)
      collisions = []
      parent_flip = (parent_xform.xaxis*parent_xform.yaxis)%parent_xform.zaxis < 0 ? -1 : 1
      parent_scale = [
        X_AXIS.transform(parent_xform).length,
        Y_AXIS.transform(parent_xform).length,
        Z_AXIS.transform(parent_xform).length * parent_flip
      ]
      parent_shape = group.get_attribute('SPOBJ', 'shape', nil)
      parent_shape = group.get_attribute('SPOBJ', 'advancedShape', nil) unless parent_shape
      parent_shape = nil unless %w(box cylinder cone sphere chamfer capsule).include?(parent_shape)
      found = false
      unless parent_shape
        group.entities.each { |e|
          next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
          found = true
          next if e.get_attribute('SPOBJ', 'ignore', false)
          next if e.attribute_dictionary('SPJOINT')
          shape = e.get_attribute('SPOBJ', 'shape', nil)
          shape = e.get_attribute('SPOBJ', 'advancedShape', nil) unless shape
          if %w(box cylinder cone sphere chamfer capsule).include?(shape)
            # Bounding box must be relative to the parent's transformation
            # matrix, multiplied by the parent's scale.
            # Center must be relative to the parent's transformation matrix,
            # multiplied by the parent's scale.
            tra = xform ? xform * e.transformation : e.transformation
            mat = tra.to_a
            flip = (tra.xaxis*tra.yaxis)%tra.zaxis < 0 ? -1 : 1
            zaxis = flip < 0 ? tra.zaxis.reverse : tra.zaxis
            bb = MSketchyPhysics3.get_definition(e).bounds
            center = bb.center
            size = [bb.width, bb.height, bb.depth]
            center.transform!(tra)
            for i in 0..2
              center[i] *= parent_scale[i]
              size[i] *= parent_scale[i].abs * Geom::Vector3d.new(mat[i*4,3]).length
            end
            final_xform = Geom::Transformation.new(tra.xaxis, tra.yaxis, zaxis, center)
            if parent_flip < 0
              rot = Geom::Transformation.rotation(center, Z_AXIS, Math::PI)
              final_xform = rot * final_xform
            end
            col = MSketchyPhysics3::NewtonServer.createCollision(
              shape,
              size.pack('f*'),
              final_xform.to_a.pack('f*'),
              [].pack('f*')
            )
            collisions << col.to_i
          elsif %w(convexhull convexhull2).include?(shape)
            pts = get_vertices_from_faces(e, shape == 'convexhull2', true)
            # All points shall be relative to the parent's transformation
            # matrix, multiplied by the parent's scale.
            if xform
              pts.each { |pt| pt.transform!(xform) }
            end
            next if pts.size < 4
            pts.each { |pt|
              for i in 0..2; pt[i] *= parent_scale[i] end
            }
            vcloud = [pts.size] + pts.flatten
            col = MSketchyPhysics3::NewtonServer.createCollision(
              'convexhull',
              [].pack('f*'),
              Geom::Transformation.new().to_a.pack('f*'),
              vcloud.pack('f*')
            )
            collisions << col.to_i
          else
            e.delete_attribute('SPOBJ', 'shape')
            e.delete_attribute('SPOBJ', 'advancedShape')
            sub_tra = ( xform ? xform * e.transformation : e.transformation )
            collisions.concat createDefaultCollision(e, parent_xform, sub_tra)
          end
        }
      end
      unless found
        parent_shape = 'box' unless parent_shape
        tra = xform ? xform : Geom::Transformation.new
        mat = tra.to_a
        flip = (tra.xaxis*tra.yaxis)%tra.zaxis < 0 ? -1 : 1
        zaxis = flip < 0 ? tra.zaxis.reverse : tra.zaxis
        bb = MSketchyPhysics3.get_definition(group).bounds
        center = bb.center
        size = [bb.width, bb.height, bb.depth]
        center.transform!(tra)
        for i in 0..2
          center[i] *= parent_scale[i]
          size[i] *= parent_scale[i].abs * Geom::Vector3d.new(mat[i*4,3]).length
        end
        final_xform = Geom::Transformation.new(tra.xaxis, tra.yaxis, zaxis, center)
        if parent_flip < 0
          rot = Geom::Transformation.rotation(center, Z_AXIS, Math::PI)
          final_xform = rot * final_xform
        end
        col = MSketchyPhysics3::NewtonServer.createCollision(
          parent_shape,
          size.pack('f*'),
          final_xform.to_a.pack('f*'),
          [].pack('f*')
        )
        collisions << col.to_i
      end
      return collisions
    end

    def createCompound2Collision(group, parent_xform, xform = nil)
      # 1. All faces within the group are considered a convex collision.
      # 2. A group inside the main group either becomes a predefined collision,
      # like box, sphere, cone, convexhull or applied number 1 if collision
      # shape is not assigned.
      collisions = []
      verts = []
      parent_flip = (parent_xform.xaxis*parent_xform.yaxis)%parent_xform.zaxis < 0 ? -1 : 1
      parent_scale = [
        X_AXIS.transform(parent_xform).length,
        Y_AXIS.transform(parent_xform).length,
        Z_AXIS.transform(parent_xform).length * parent_flip
      ]
      group.entities.each { |e|
        if e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
          next if e.get_attribute('SPOBJ', 'ignore', false)
          next if e.attribute_dictionary('SPJOINT')
          shape = e.get_attribute('SPOBJ', 'shape', nil)
          shape = e.get_attribute('SPOBJ', 'advancedShape', nil) unless shape
          if %w(box cylinder cone sphere chamfer capsule).include?(shape)
            # Bounding box must be relative to the parent's transformation
            # matrix, multiplied by the parent's scale.
            # Center must be relative to the parent's transformation matrix,
            # multiplied by the parent's scale.
            tra = xform ? xform * e.transformation : e.transformation
            mat = tra.to_a
            flip = (tra.xaxis*tra.yaxis)%tra.zaxis < 0 ? -1 : 1
            zaxis = flip < 0 ? tra.zaxis.reverse : tra.zaxis
            bb = MSketchyPhysics3.get_definition(e).bounds
            center = bb.center
            size = [bb.width, bb.height, bb.depth]
            center.transform!(tra)
            for i in 0..2
              center[i] *= parent_scale[i]
              size[i] *= parent_scale[i].abs * Geom::Vector3d.new(mat[i*4,3]).length
            end
            final_xform = Geom::Transformation.new(tra.xaxis, tra.yaxis, zaxis, center)
            if parent_flip < 0
              rot = Geom::Transformation.rotation(center, Z_AXIS, Math::PI)
              final_xform = rot * final_xform
            end
            col = MSketchyPhysics3::NewtonServer.createCollision(
              shape,
              size.pack('f*'),
              final_xform.to_a.pack('f*'),
              [].pack('f*')
            )
            collisions << col.to_i
          elsif %w(convexhull convexhull2).include?(shape)
            pts = get_vertices_from_faces(e, shape == 'convexhull2', true)
            # All points shall be relative to the parent's transformation
            # matrix, multiplied by the parent's scale.
            if xform
              pts.each { |pt| pt.transform!(xform) }
            end
            next if pts.size < 4
            pts.each { |pt|
              for i in 0..2; pt[i] *= parent_scale[i] end
            }
            vcloud = [pts.size] + pts.flatten
            col = MSketchyPhysics3::NewtonServer.createCollision(
              'convexhull',
              [].pack('f*'),
              Geom::Transformation.new().to_a.pack('f*'),
              vcloud.pack('f*')
            )
            collisions << col.to_i
          else
            e.delete_attribute('SPOBJ', 'shape')
            e.delete_attribute('SPOBJ', 'advancedShape')
            sub_tra = ( xform ? xform * e.transformation : e.transformation )
            collisions.concat createCompound2Collision(e, parent_xform, sub_tra)
          end
          next
        end
        next unless e.is_a?(Sketchup::Face)
        e.vertices.each { |v| verts << v.position.to_a }
      }
      if xform
        verts.each { |pt| pt.transform!(xform) }
      end
      if verts.size > 4
        bb = MSketchyPhysics3.get_definition(group).bounds
        tra = group.transformation
        verts.each { |pt|
          for i in 0..2; pt[i] *= parent_scale[i] end
        }
        vcloud = [verts.size] + verts.flatten
        size = [bb.width * parent_scale[0], bb.height * parent_scale[1], bb.depth * parent_scale[2]]
        col = MSketchyPhysics3::NewtonServer.createCollision(
          'convexhull',
          size.pack('f*'),
          Geom::Transformation.new().to_a.pack('f*'),
          vcloud.pack('f*')
        )
        collisions << col.to_i
      end
      return collisions
    end

    def createStaticMesh2Collision(group)
      faces = get_polygons_from_faces(group, true, false)
      tra = group.transformation
      flip = (tra.xaxis*tra.yaxis)%tra.zaxis < 0 ? -1 : 1
      scale = [
        X_AXIS.transform(tra).length,
        Y_AXIS.transform(tra).length,
        Z_AXIS.transform(tra).length * flip
      ]
      faces.each { |face|
        face.reverse!  if flip < 0
        face.each { |pt|
          for i in 0..2; pt[i] *= scale[i] end
        }
      }
      tris = faces.flatten
      MSketchyPhysics3::NewtonServer.createCollisionMesh(tris.pack('f*'), tris.size/9).to_i
    end

    def createConvexHullVerts(group)
        tra = group.transformation
        flip = (tra.xaxis*tra.yaxis)%tra.zaxis < 0 ? -1 : 1
        scale = [
          X_AXIS.transform(tra).length,
          Y_AXIS.transform(tra).length,
          Z_AXIS.transform(tra).length * flip
        ]
        verts = [0] # Index 0 is placeholder for vertices count.
        MSketchyPhysics3.get_entities(group).each { |ent|
            next unless ent.is_a?(Sketchup::Face)
            ent.vertices.each { |v|
                pos = v.position.to_a
                for i in 0..2; pos[i] *= scale[i]; end
                verts = verts + pos
            }
        }
        verts[0] = (verts.size-1)/3
        return verts
    end

    def createStaticMeshCollision(group)
        tra = group.transformation
        flip = (tra.xaxis*tra.yaxis)%tra.zaxis < 0 ? -1 : 1
        scale = [
          X_AXIS.transform(tra).length,
          Y_AXIS.transform(tra).length,
          Z_AXIS.transform(tra).length * flip
        ]
        tris = []
        MSketchyPhysics3.get_entities(group).each { |ent|
            next unless ent.is_a?(Sketchup::Face)
            ent.mesh.polygons.each_index { |pi|
                face = ent.mesh.polygon_points_at( pi+1 )
                face.reverse! if flip < 0
                face.each { |pt|
                    for i in 0..2; pt[i] *= scale[i] end
                    tris = tris + pt.to_a
                }
            }
        }

        MSketchyPhysics3::NewtonServer.createCollisionMesh(tris.to_a.pack('f*'), tris.size/9).to_i
    end

    def showCollision(group, body, bEmbed = false)
        unless @collisionBuffer
            #@collisionBuffer = Array.new.fill(255.chr, 0..400*1024).join
            if RUBY_VERSION =~ /1.8/
              @collisionBuffer = (0.chr*4*400*512).to_ptr
            else
              @collisionBuffer = 0.chr*4*400*512
            end
        end
        if bEmbed
            colGroup = MSketchyPhysics3.get_entities(group).add_group
        else
            colGroup = Sketchup.active_model.entities.add_group
        end
        faceCount = MSketchyPhysics3::NewtonServer.getBodyCollision(body, @collisionBuffer, @collisionBuffer.size)
        # Each face represents point size and maximum of 4 points, while each
        # point represents 3 floats = maximum of 13 floats per face.
        # Edit: Although some faces have more points than 4. Just multiply face count by 50.
        cb = RUBY_VERSION =~ /1.8/ ? @collisionBuffer.to_a("F#{faceCount*50}") : @collisionBuffer.unpack('F'*faceCount*50)
        pos = 0
        scale = Sketchup.active_model.get_attribute('SPSETTINGS', 'worldscale', 9.0).to_f
        scale = 1 if scale.zero?
        ents = colGroup.entities
        n = 0
        for i in 0...faceCount
          pts = []
          for j in 0...cb[n].to_i/3
            pts << [cb[n+j*3+1]*scale, cb[n+j*3+2]*scale, cb[n+j*3+3]*scale]
          end
          for i in 0...(pts.size-1)
            ents.add_line(pts[i], pts[i+1])
          end
          ents.add_line(pts[-1], pts[0])
          n += (cb[n]+1)
        end
        colGroup.set_attribute('SPOBJ', 'ignore', true)
        colGroup.set_attribute('SPOBJ', 'EmbeddedGeometryObject', true)
        colGroup.transform!(group.transformation.inverse) if bEmbed
        @tempObjects << colGroup
        colGroup
    end

    # Compatibility with prior models.
    alias ShowCollision showCollision

    def updateEmbeddedGeometry(group, body)
        cd = MSketchyPhysics3.get_definition(group)
        cd.entities.each { |e|
            e.erase! if e.get_attribute('SPOBJ', 'EmbeddedGeometryObject', false)
        }
        if group.get_attribute('SPOBJ', 'showcollision', false)
            showCollision(group, body, true)
        end
    end

    # Compatibility with prior models.
    alias UpdateEmbeddedGeometry updateEmbeddedGeometry

    def findGroupNamed(name)
        name = name.to_s.downcase
        @DynamicObjectList.each_index { |di|
            return @DynamicObjectList[di] if @DynamicObjectList[di].name.downcase == name
        }
        puts "Didn't find body #{name}" if $debug
        nil
    end

    # Compatibility with prior models.
    alias FindGroupNamed findGroupNamed

    def findBodyNamed(name)
        name = name.downcase
        @DynamicObjectList.each_index { |di|
            return @DynamicObjectBodyRef[di] if @DynamicObjectList[di].name.downcase == name
        }
        puts "Didn't find body #{name}" if $debug
        nil
    end

    # Compatibility with prior models.
    alias FindBodyNamed findBodyNamed

    def findEntityWithID(id)
        @AllCollisionEntities.each { |ent|
            puts ent.entityID.to_s+"=="+id.to_s if $debug
            return ent if ent.entityID == id
        }
        puts "Didn't find entity #{id}" if $debug
        nil
    end

    # Compatibility with prior models.
    alias FindEntityWithID findEntityWithID

    def findBodyWithID(id)
        @DynamicObjectList.each_index { |di|
            puts @DynamicObjectList[di].entityID.to_s+"=="+id.to_s if $debug
            return @DynamicObjectBodyRef[di] if @DynamicObjectList[di].entityID == id
        }
        puts "Didn't find body #{id}" if $debug
        nil
    end

    # Compatibility with prior models.
    alias FindBodyWithID findBodyWithID

    def findBodyFromInstance(componentInstance)
        @DynamicObjectList.each_index { |di|
            return @DynamicObjectBodyRef[di] if @DynamicObjectList[di] == componentInstance
        }
        nil
    end

    # Compatibility with prior models.
    alias FindBodyFromInstance findBodyFromInstance

    def findJointNamed(name)
        @AllJoints.each { |j|
            return j if j.get_attribute('SPJOINT', 'name', 'none') == name
        }
        nil
    end

    # Compatibility with prior models.
    alias FindJointNamed findJointNamed

    @@autoExplodeInstanceObserver = nil

    class AutoExplodeInstanceObserver
        def onComponentInstanceAdded(definition, instance)
            puts [definition, instance]
            definition.remove_observer(self)
            UI.start_timer(0.25, false){
                #ents = definition.instances[0].explode
                SketchyPhysicsClient.openComponent(definition.instances[0])
            }
        end
    end

    def self.physicsSafeCopy
        ents = Sketchup.active_model.selection
        cd = Sketchup.active_model.definitions.add
        unless @@autoExplodeInstanceObserver
            @@autoExplodeInstanceObserver = AutoExplodeInstanceObserver.new
        end
        cd.add_observer(@@autoExplodeInstanceObserver)
        ents.each { |ent|
            next unless ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
            #~ resetAxis(ent)
            grp = cd.entities.add_instance(MSketchyPhysics3.get_definition(ent), ent.transformation)
        }
        #~ resetAxis(cd)
        Sketchup.active_model.place_component(cd)
        return

        prefix = "_" + rand(10000).to_s
        newGrps = []
        ents.each { |ent|
            next unless ent.is_a?(Sketchup::Group)
            #~ ent.make_unique
            newGrps << ent
            #~ resetAxis(ent)
            MSketchyPhysics3::Group.get_joints(ent).each { |j|
                # Rename joint
                #~ j.make_unique
                newname = j.get_attribute('SPJOINT', 'name', nil)+prefix
                j.set_attribute('SPJOINT', 'name', newname)
                #puts "renamed #{newname}"
            }
            renamedconnections = []
            MSketchyPhysics3::Group.get_connections(ent).each { |c|
                # Rename joint
                renamedconnections.push(c+prefix) if c
            }
            #puts "renamed connections #{renamedconnections.inspect}"
            ent.set_attribute('SPOBJ', 'parentJoints', renamedconnections) if renamedconnections.length > 0
        }
    end

    def self.openComponent(group)
        ents = group.explode
        prefix = "_" + rand(10000).to_s
        ents.each { |ent|
            if ent.is_a?(Sketchup::Group)
                #~ ent.make_unique
                #~ resetAxis(ent)
                MSketchyPhysics3::Group.get_joints(ent).each { |j|
                    # Rename joint
                    #~ j.make_unique
                    newname = j.get_attribute('SPJOINT', 'name', nil)+prefix
                    j.set_attribute('SPJOINT', 'name', newname)
                    #puts "renamed #{newname}"
                }
                renamedconnections = []
                MSketchyPhysics3::Group.get_connections(ent).each { |c|
                    #puts "rename connection"
                    renamedconnections.push(c+prefix) if c
                }
                #puts "renamed connections #{renamedconnections.inspect}"
                ent.set_attribute('SPOBJ', 'parentJoints', renamedconnections) if renamedconnections.length > 0
            end
        }
    end

    def self.initDirectInput
        MSketchyPhysics3::JoyInput.initInput
    end

    def freeDirectInput
        MSketchyPhysics3::JoyInput.freeInput
    end

    def readJoystick
        MSketchyPhysics3::JoyInput.readJoystick(@joyDataBuffer)
    end

    def setFrameRate(rate)
        @frameRate = rate.to_i
    end

    private

    def handle_operation(message = nil, &block)
        block.call
        return false if @deactivate_called
        true
    rescue Exception => e
        @error = message ? "\n#{message}\nException:\n  #{e}\nLocation:\n  #{e.backtrace[0..1].join("\n")}" : e
        SketchyPhysicsClient.safePhysicsReset
        false
    end

    def handle_operation2(message = nil, &block)
        block.call
        true
    rescue Exception => e
        err = message ? "\n#{message}\nException:\n  #{e}\nLocation:\n  #{e.backtrace[0..1].join("\n")}" : e
        puts err
    end

    def update_status_text
      Sketchup.status_text = "Frame : #{@frame}    FPS : #{@_fps[:val]}    #{@note}"#~ if @mouse_enter
    end

    public

    def focus_control
        dlg = MSketchyPhysics3.control_panel_dialog
        dlg.bring_to_front if dlg
    end

    # Set cursor id.
    # @param [Symbol, String, Fixnum] id
    # @return [Boolean] success
    def setCursor(id = :hand)
        if id.is_a?(String) or id.is_a?(Symbol)
          id = MSketchyPhysics3::CURSORS[id.to_s.downcase.gsub(' ', '_').to_sym]
          return false unless id
        end
        @cursor_id = id.to_i
        true
    end

    # Get cursor id.
    # @return [Fixnum]
    def getCursor(id)
        @cursor_id
    end

    # Enable/Disable drag tool.
    # @param [Boolean] state
    def pick_drag_enabled=(state)
        @pick_drag_enabled = state ? true : false
    end

    alias pickAndDragEnabled= pick_drag_enabled=

    # Determine whether the drag tool is enabled.
    # @return [Boolean]
    def pick_drag_enabled?
        @pick_drag_enabled
    end

    alias pickAndDragEnabled? pick_drag_enabled?

    def initialize_standard
        model = Sketchup.active_model
        view = model.active_view
        # Buffer used to hold results from reading Joystick
        if RUBY_VERSION =~ /1.8/
          @joyDataBuffer = Array.new.fill(0.0, 0..16).pack('f*').to_ptr
        else
          @joyDataBuffer = 0.chr*4*16
        end
        @@frame = 0
        @frame = 0
        @@bPause = false
        @_time = { :start => 0, :end => 0, :last => 0, :sim => 0, :total => 0 }
        @_fps = { :val => 0, :update_rate => 10, :last => 0, :change => 0 }
        @note = 'Click and drag to move. Hold SHIFT while dragging to lift.'
        @pause_updated = false
        @bWasStopped = false
        @mouse_enter = false
        @error = nil
        @cameraTarget = nil
        @cameraParent = nil
        @savedCameraPosition = nil
        @recordSamples = []
        @recordCamera = {}
        @DynamicObjectList = []
        @DynamicObjectResetPositions = []
        @DynamicObjectBodyRef = []
        @AllMagnets = []
        @AllJoints = []
        @AllJointChildren = []
        @AllCollisionEntities = []
        @controlledJoints = []
        @tempObjects = []
        @allForces = []
        @allThrusters = []
        @allTickables = []
        @allEmitters = []
        @emitted = {}
        @dyingObjects = []
        @bodyToGroup = {}
        @pickedBody = nil
        @mouseX = 0
        @mouseY = 0
        @ctrlDown = false
        @shiftDown = false
        @tabDown = false
        @cursorCount = 0
        @CursorMagnet = nil
        @magnetLocation = nil
        @attachPoint = nil
        @attachPointWithScale = nil
        @attachWorldLocation = nil
        @controllerContext = nil
        @simulationContext = nil
        @bb = Geom::BoundingBox.new
        @drag = {
            :line_width     => 2,
            :line_stipple   => '',
            :point_size     => 15,
            :point_style    => 4,
            :point_color    => Sketchup::Color.new(0,0,0),
            :line_color     => Sketchup::Color.new(255,0,0)
        }
        @cursor_id = 671
        @@origAxis = {}
        @last_drag_frame = 0
        @pick_drag_enabled = true
        @clicked_body = nil
        @collisionBuffer = nil
        @activate_called = false
        @deactivate_called = false
        @original_transformations = {}
        @orig_force_callback = nil
        @finished_activating = false
        $sketchyPhysicsToolInstance = self
        # Compatibility for some prior scripted models.
        if $sketchyphysics_version_loaded == 3.2
          activate_standard(false)
        end
    end

    def initialize
      initialize_standard
    end

    attr_reader :bb


    def activate_standard(set_animation = true)
        return if @activate_called
        @activate_called = true
        model = Sketchup.active_model
        view = model.active_view
        # Close active path
        state = true
        while state
            state = model.close_active
        end
        # Wrap operations
        op_name = 'SketchyPhysics Simulation'
        if Sketchup.version.to_i > 6
            model.start_operation(op_name, true, false, false)
        else
            model.start_operation(op_name)
        end
        # Clear selection.
        model.selection.clear
        # Save original positions
        model.entities.each { |e|
          if e.is_a?(Sketchup::Group) or e.is_a?(Sketchup::ComponentInstance)
            next if e.get_attribute('SPOBJ', 'ignore')
            @original_transformations[e.entityID] = e.transformation
            next if MSketchyPhysics3.get_definition(e).instances.size < 2
            # Allow components to operate correctly in simulation.
            e.make_unique
          end
        }
        # Initialize Newton Server
        MSketchyPhysics3::NewtonServer.init()
        explodeList = []
        model.entities.each { |ent|
            explodeList << ent if ent.get_attribute('SPOBJ', 'component', false)
        }
        @CursorMagnet = MSketchyPhysics3::NewtonServer.magnetAdd([0,0,0].to_a.pack('f*'))
        @AllMagnets << @CursorMagnet
        if $spExperimentalFeatures
            @controllerContext = MSketchyPhysics3::SP3xControllerContext.new
        else
            @controllerContext = MSketchyPhysics3::ControllerContext.new
        end
        @simulationContext = SP3xSimulationContext.new(model)
        $curPhysicsSimulation = @simulationContext
        explodeList.each { |ent| openComponent(ent) }
        checkModelUnits
        # Parse and set physics constants.
        dict = model.attribute_dictionary('SPSETTINGS')
        unless dict
            MSketchyPhysics3.setDefaultPhysicsSettings
            dict = model.attribute_dictionary('SPSETTINGS')
        end
        if dict
            dict.each_pair { |key, value|
                MSketchyPhysics3::NewtonServer.newtonCommand('set', "#{key} #{value}")
            }
        end
        @frameRate = model.get_attribute('SPSETTINGS', 'framerate', 3)
        state = handle_operation { dumpCollision }
        return unless state
        # Find joints
        puts 'Finding joints' if $debug
        model.entities.each { |ent|
            next unless ent.is_a?(Sketchup::Group)
            type = ent.get_attribute('SPJOINT', 'type', nil)
            if type == 'magnet'
                strength = ent.get_attribute('SPJOINT', 'strength', 0.0)
                range = ent.get_attribute('SPJOINT', 'range', 0.0)
                falloff = ent.get_attribute('SPJOINT', 'falloff', 0.0)
                duration = ent.get_attribute('SPJOINT', 'duration', 0)
                delay = ent.get_attribute('SPJOINT', 'delay', 0)
                rate = ent.get_attribute('SPJOINT', 'rate', 0)
                MSketchyPhysics3::NewtonServer.addGlobalForce(
                    ent.transformation.origin.to_a.pack('f*'),
                    [strength, range, falloff].pack('f*'),
                    duration, delay, rate)
            elsif type != nil
                # Save joints for later processing.
                @AllJoints << ent
                puts "Found joint #{ent.entityID}" if $debug
            else
                ent.entities.each { |gent|
                    next unless gent.is_a?(Sketchup::Group)
                    next unless gent.get_attribute('SPJOINT', 'type', nil)
                    gent.set_attribute('SPOBJ', 'body', ent.get_attribute('SPOBJ', 'body', nil))
                    # Save joints for later processing.
                    @AllJoints << gent
                }
            end
        }
        # Init control sliders.
        MSketchyPhysics3.initJointControllers
        # Find joint/joint connections. gears.
        @AllJoints.each { |joint|
            parents = JointConnectionTool.getParentJointNames(joint)
            next if parents.empty?
            next unless joint.get_attribute('SPJOINT', 'gearjoint', nil)
            #puts "Joint/Joint"
            gname = joint.get_attribute('SPJOINT', 'gearjoint', nil)
            gjoint = findJointNamed(gname)
            next unless gjoint
            if joint.parent.is_a?(Sketchup::ComponentDefinition)
                pgrp = joint.parent.instances[0]
                address = pgrp.get_attribute('SPOBJ', 'body', 0).to_i
                next if address.zero?
                bodya = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(address) : Fiddle::Pointer.new(address)
                pina = (pgrp.transformation*joint.transformation).zaxis.to_a
            end
            if gjoint.parent.is_a?(Sketchup::ComponentDefinition)
                pgrp = gjoint.parent.instances[0]
                address = pgrp.get_attribute('SPOBJ', 'body', 0).to_i
                next if address.zero?
                bodyb = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(address) : Fiddle::Pointer.new(address)
                pinb = (pgrp.transformation*gjoint.transformation).zaxis.to_a
            end
            ratio = joint.get_attribute('SPJOINT', 'ratio', 1.0)
            gtype = joint.get_attribute('SPJOINT', 'geartype', nil)
            #puts "Making gear #{gtype}"
            if bodya != nil && bodyb != nil && gtype != nil
                jnt = MSketchyPhysics3::NewtonServer.createGear(gtype,
                    pina.pack('f*'), pinb.pack('f*'),
                    bodya, bodyb, ratio)
                if jnt != 0 && joint.get_attribute('SPJOINT', 'GearConnectedCollide', false)
                    jnt_ptr = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(jnt.to_i) : Fiddle::Pointer.new(jnt.to_i)
                    MSketchyPhysics3::NewtonServer.setJointCollisionState(jnt_ptr, 1)
                end
            end
        }
        # Now create joints
        model.selection.clear
        @AllJointChildren.each{ |ent|
            jnames = JointConnectionTool.getParentJointNames(ent)
            next unless jnames.is_a?(Array)
            jnames.each { |jointParentName|
                puts "Connecting foo #{ent} to #{jointParentName}." if $debug
                joint = findJointNamed(jointParentName)
                next unless joint
                jointType = joint.get_attribute('SPJOINT', 'type', nil)
                puts "Created #{joint.get_attribute('SPJOINT', 'name', 'error')}" if $debug
                defaultJointBody = nil
                jointChildBody = findBodyWithID(ent.entityID)
                # TODO. This might not be needed.
                jointChildBody = 0 unless jointChildBody
                if joint.parent.is_a?(Sketchup::ComponentDefinition)
                    pgrp = joint.parent.instances[0]
                    address = pgrp.get_attribute('SPOBJ', 'body', 0).to_i
                    next if address.zero?
                    defaultJointBody = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(address) : Fiddle::Pointer.new(address)
                    parentXform = pgrp.transformation
                else
                    parentXform = Geom::Transformation.new
                end
                xform = parentXform*joint.transformation
                limits = []
                min = joint.get_attribute('SPJOINT', 'min', 0).to_f
                max = joint.get_attribute('SPJOINT', 'max', 0).to_f
                type = joint.get_attribute('SPJOINT', 'type', nil)
                if %w(hinge servo corkscrew ball).include?(type)
                  if joint.get_attribute('SPJOINT', 'angleUnit', nil) == 'radian'
                    r = 180/Math::PI
                    min *= r
                    max *= r
                  end
                elsif %w(slider piston).include?(type)
                  r = case joint.get_attribute('SPJOINT', 'lengthUnit', nil)
                    when 'millimeter'; 0.0393701
                    when 'centimeter'; 0.393701
                    when 'decimeter'; 3.93701
                    when 'meter'; 39.3701
                    when 'inch'; 1
                    when 'foot'; 12
                    when 'yard'; 36
                  else
                    1.0
                  end
                  min *= r
                  max *= r
                end
                limits << min
                limits << max
                limits << joint.get_attribute('SPJOINT', 'accel', 0).to_f
                limits << joint.get_attribute('SPJOINT', 'damp', 0).to_f
                limits << joint.get_attribute('SPJOINT', 'rate', 0).to_i
                limits << joint.get_attribute('SPJOINT', 'range', 0).to_f
                limits << joint.get_attribute('SPJOINT', 'breakingForce', 0).to_f
                controller = joint.get_attribute('SPJOINT', 'controller', nil)
                controller = nil if controller.is_a?(String) && controller.strip.empty?
                # Convert if its a 2.0 joint.
                MSketchyPhysics3.convertControlledJoint(joint) if controller
                controller = joint.get_attribute('SPJOINT', 'Controller', nil)
                controller = nil if controller.is_a?(String) && controller.strip.empty?
                # Allow conversion of old and new style joints
                unless controller
                    jointType = 'hinge' if jointType == 'servo'
                    jointType = 'slider' if jointType == 'piston'
                else
                    if jointType == 'hinge'
                        jointType = 'servo'
                        if limits[0].zero? && limits[1].zero?
                            limits[0] = -180.0
                            limits[1] = 180.0
                        end
                    elsif jointType == 'slider'
                        jointType = 'piston'
                    end
                    #puts "Promoted joint #{jointType}" if $debug
                end
                #puts "Joint parents: #{JointConnectionTool.getParentJointNames(joint).inspect}"
                # detect joint to joint connection
                # detect parent body for each joint
                # determine gear type based on joint types
                # get ratio (where?)
                pinDir = xform.zaxis.to_a+xform.yaxis.to_a
                # Old style gears. REMOVE.
                if %w(gear pulley wormgear).include?(jointType)
                    #puts "Gear parent: #{defaultJointBody.class}, child: #{jointChildBody}"
                    ratio = joint.get_attribute('SPJOINT', 'ratio', 1.0)
                    jnt = MSketchyPhysics3::NewtonServer.createGear(jointType,
                        pinDir.pack('f*'), pinDir.pack('f*'),
                        jointChildBody, defaultJointBody, ratio)
                else
                    jnt = MSketchyPhysics3::NewtonServer.createJoint(jointType,
                        xform.origin.to_a.pack('f*'),
                        pinDir.pack('f*'),
                        jointChildBody, defaultJointBody,
                        limits.pack('f*'))
                    #puts joint.get_attribute('SPJOINT', 'ConnectedCollide', 0)
                    # Set collision between connected bodies.
                    if jnt != 0
                        joint.set_attribute('SPJOINT', 'jointPtr', jnt.to_i)
                        if jnt != 0 && joint.get_attribute('SPJOINT', 'ConnectedCollide', false)
                            jnt_ptr = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(jnt.to_i) : Fiddle::Pointer.new(jnt.to_i)
                            MSketchyPhysics3::NewtonServer.setJointCollisionState(jnt_ptr, 1)
                        end
                        # Handle controlled joints.
                        # controller = joint.get_attribute('SPJOINT', 'controller', '')
                        if controller
                            @controlledJoints << joint
                            value = limits[0] + (limits[1]-limits[0])/2
                            value = 0.5 # utb 0.5 jan 7.
                            #MSketchyPhysics3::createController(controller, value, 0.0, 1.0)
                            #puts 'Controlled joint'
                        end
                    end
                end
            }
        }
        #handleAttachments
        setupCameras
        # Initialize timers
        t = Time.now
        @_time[:start] = t
        @_time[:last] = t
        @_fps[:last] = t
        @finished_activating = true
        # Call onStart event
        state = handle_operation('onStart error:'){
            @simulationContext.doOnStart
        }
        return unless state
        MSketchyPhysics3.showControlPanel
        view.animation = self if set_animation
    rescue Exception => e
        @error = "An error occurred while starting simulation:\n#{e}\n#{e.backtrace.first}"
        SketchyPhysicsClient.safePhysicsReset
    end

    def activate
      activate_standard(true)
    end

    def deactivate_standard(view)
        return if @deactivate_called
        @deactivate_called = true
        model = Sketchup.active_model
        model.active_view.animation = nil
        begin
            @simulationContext.doOnEnd
        rescue Exception => e
            @error = "onEnd error:\nException:\n  #{e}\nLocation:\n  #{e.backtrace.first}" unless @error
        end
        $sketchyPhysicsToolInstance = nil
        $curPhysicsSimulation = nil
        if @savedCameraPosition
            model.active_view.camera = @savedCameraPosition
            @savedCameraPosition = nil
        end
        # Erase all objects added during simulation.
        @tempObjects.each { |ent| ent.erase! if ent.valid? }
        # Purge unused stuff
        #~ model.definitions.purge_unused
        #~ model.materials.purge_unused
        # Reset original axis
        model.definitions.each { |cd|
            next if cd.instances.empty?
            orig = @@origAxis[cd.entityID]
            next unless orig
            orig = orig.clone
            for i in 0..2; orig[i] *= -1; end
            cd.entities.transform_entities(Geom::Transformation.new(orig), cd.entities.to_a)
            cd.invalidate_bounds if cd.respond_to?(:invalidate_bounds)
            cd.instances.each { |ci|
                rel_center = orig.transform(ci.transformation)
                matrix = ci.transformation.to_a
                matrix[12..14] = rel_center.to_a
                ci.move! Geom::Transformation.new(matrix)
            }
        }
        @@origAxis.clear
        # Reset original transformations.
        model.entities.each { |ent|
            if ent.is_a?(Sketchup::Group) or ent.is_a?(Sketchup::ComponentInstance)
                tra = @original_transformations[ent.entityID]
                ent.move!(tra) if tra
            end
        }
        #@DynamicObjectList.each_index { |ci|
        #   next unless @DynamicObjectList[ci].valid?
        #   @DynamicObjectList[ci].move! @DynamicObjectResetPositions[ci]
        #}
        # Erase unused attributes
        model.definitions.each { |cd|
            cd.instances.each { |inst|
                attrib = inst.attribute_dictionary('SPOBJ', false)
                if attrib
                  to_remove = %w(body savedScale __lookAtJoint __force nexttickframe lasttouchframe lastemissionframe)
                  attrib.each { |key, value|
                    if(value == '' || value.nil? || value == false ||
                       (key == 'parentJoints' && (value == [] || !value.is_a?(Array))))
                      to_remove << key
                    end
                  }
                  to_remove.each { |k| attrib.delete_key(k) }
                  if attrib.length == 0
                    inst.delete_attribute('SPOBJ')
                  end
                end
                inst.delete_attribute('SPJOINT', 'jointPtr')
            }
        }
        model.attribute_dictionaries.delete('SPOBJ')
        # Commit operation. Using abort_operation would be a better choice, but
        # its not safe.
        model.commit_operation
        # Destroy Newton world
        MSketchyPhysics3::NewtonServer.stop
        # Free direct input
        freeDirectInput
        # Clear big variables.
        @joyDataBuffer = nil
        @cameraTarget = nil
        @cameraParent = nil
        @savedCameraPosition = nil
        @original_transformations.clear
        @DynamicObjectResetPositions.clear
        @DynamicObjectBodyRef.clear
        @AllMagnets.clear
        @AllJoints.clear
        @AllJointChildren.clear
        @AllCollisionEntities.clear
        @controlledJoints.clear
        @tempObjects.clear
        @allForces.clear
        @allThrusters.clear
        @allTickables.clear
        @allEmitters.clear
        @emitted.clear
        @dyingObjects.clear
        @bodyToGroup.clear
        @pickedBody = nil
        @bb.clear
        @CursorMagnet = nil
        @controllerContext = nil
        @simulationContext = nil
        @collisionBuffer = nil
        # Refresh view
        model.active_view.invalidate
        # Show info
        if @error
            msg = "SketchyPhysics Simulation was aborted due to an error!\n#{@error}\n\n"
            puts msg
            UI.messagebox(msg)
        elsif @finished_activating
            @_time[:end] = Time.now
            @_time[:total] = @_time[:end] - @_time[:start]
            @_time[:sim] += @_time[:end] - @_time[:last] unless @@bPause
            average_fps = (@_time[:sim].zero? ? 0 : (@frame / @_time[:sim]).round)
            puts 'SketchyPhysics Simulation Results:'
            printf("  frames          : %d\n", @frame)
            printf("  average FPS     : %d\n", average_fps)
            printf("  simulation time : %.2f seconds\n", @_time[:sim])
            printf("  total time      : %.2f seconds\n\n", @_time[:total])
        end
        unless @recordSamples.empty?
            result = UI.messagebox('Save animation?', MB_YESNO)
            case result
            when 6 #yes
                if Sketchup.version.to_i > 6
                  model.start_operation('Save Animation', true)
                else
                  model.start_operation('Save Animation')
                end
                @DynamicObjectList.each_index { |ci|
                    ent = @DynamicObjectList[ci]
                    if @recordSamples[ci] != nil && @DynamicObjectList[ci] != nil && @DynamicObjectList[ci].valid?
                        @DynamicObjectList[ci].set_attribute('SPTAKE', 'samples', @recordSamples[ci])
                    end
                }
                Sketchup.active_model.set_attribute('SPRECORD', 'Camera', @recordCamera.inspect)
                model.commit_operation
                # brand each group.
                # save anim data in group.
                # save anim data in model attributes.
                # compress and embed animation
            when 7 #no
            when 2 #cancel
            end
        end
        MSketchyPhysics3.closeControlPanel
        # Clear some more variables
        @error = nil
        @recordSamples.clear
        @DynamicObjectList.clear
    end

    def deactivate(view)
      deactivate_standard(view)
    end

    def handleOnTouch_standard(bodies, speed, pos)
        grpa = @bodyToGroup[bodies[0].to_i]
        return false unless grpa.valid?
        grpb = @bodyToGroup[bodies[1].to_i]
        return false unless grpb.valid?
        state = handle_operation2('onTouch or onTouching error'){
          @simulationContext.doTouching(grpa, grpb, speed, pos)
          if grpa.valid? and grpb.valid? and SketchyPhysicsClient.active?
            @simulationContext.doTouching(grpb, grpa, speed, pos)
          end
        }
        #~ return false unless state
        bodies.each { |b|
            grp = @bodyToGroup[b.to_i]
            next unless grp
            next unless grp.valid?
            $curEvalGroup = grp
            # Kinda klugy, loop should be rewritten.
            if b == bodies[0]
                $curEvalTouchingGroup = @bodyToGroup[bodies[1].to_i]
            else
                $curEvalTouchingGroup = @bodyToGroup[bodies[0].to_i]
            end
            func = grp.get_attribute('SPOBJ', 'ontouch', '').to_s
            next if func == ''
            last = grp.get_attribute('SPOBJ', 'lasttouchframe', 0)
            rate = grp.get_attribute('SPOBJ', 'touchrate', 0).to_i
            # Too early?
            next if (@@frame-last) < rate
            state = handle_operation2('touch error:'){
                eval(func, @curControllerBinding)
                grp.set_attribute('SPOBJ', 'lasttouchframe', @@frame) if grp.valid?
            }
            # Clean out value.
            #~ $curEvalTouchingGroup = nil
            #~ return false unless state
        }
        true
    end

    def handleOnTouch(bodies, speed, pos)
      handleOnTouch_standard(bodies, speed, pos)
    end

    def updateControlledJoints
        MSketchyPhysics3::JoyInput.updateInput
        cbinding = @controllerContext.getBinding(@@frame)
        @curControllerBinding = cbinding
        state = handle_operation('onTick error:'){
            @simulationContext.doOnTick(@@frame)
        }
        return false unless state
        @allTickables.each { |grp|
            $curEvalGroup = grp
            func = grp.get_attribute('SPOBJ', 'ontick', '').to_s.strip
            next if func.empty?
            next_frame = grp.get_attribute('SPOBJ', 'nexttickframe', 0)
            # Too early?
            next if @@frame < next_frame
            state = handle_operation2('Tick error:'){
                rate = grp.get_attribute('SPOBJ', 'tickrate', 0).to_i
                result = eval(func, @curControllerBinding)
                next if grp.deleted?
                if rate.zero? && result.is_a?(Numeric) && result != 0
                    grp.set_attribute('SPOBJ', 'nexttickframe', @@frame + result.to_i)
                else
                    grp.set_attribute('SPOBJ', 'nexttickframe', @@frame + rate)
                end
            }
            #~ return false unless state
        }
        @allForces.each { |grp|
            $curEvalGroup = grp
            strength = grp.get_attribute('SPOBJ', 'strength', 0.0).to_s
            state = handle_operation2("Force error:\n#{strength}"){
                value = eval(strength, cbinding)
                value = 0.0 unless value.is_a?(Numeric)
                address = grp.get_attribute('SPOBJ', '__force', 0).to_i
                next if address.zero?
                force = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(address) : Fiddle::Pointer.new(address)
                MSketchyPhysics3::NewtonServer.setForceStrength(force, value.to_f) if force
            }
            #~ return false unless state
        }
        @allThrusters.each { |grp|
            $curEvalGroup = grp
            expression = grp.get_attribute('SPOBJ', 'tstrength', 0.0).to_s
            state = handle_operation2("Thruster error:\n#{expression}"){
                value = eval(expression, cbinding)
                next unless value.is_a?(Numeric)
                address = grp.get_attribute('SPOBJ', 'body', 0).to_i
                next if address.zero?
                body = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(address) : Fiddle::Pointer.new(address)
                MSketchyPhysics3::NewtonServer.bodySetThrust(body, value.to_f) if body
            }
            #~ return false unless state
        }
        @allEmitters.each { |grp|
            $curEvalGroup = grp
            # Is it time for this object to dupe itself yet?
            ratestr = grp.get_attribute('SPOBJ', 'emitterrate', 0).to_s
            rate = nil
            state = handle_operation2("Emitter Rate error:\n#{ratestr}"){
                rate = eval(ratestr, cbinding)
            }
            #~ return false unless state
            next unless rate.is_a?(Numeric)
            next if rate.zero?
            last = grp.get_attribute('SPOBJ', 'lastemissionframe', 0)
            # Too early?
            next if (@@frame - last) < rate
            expression = grp.get_attribute('SPOBJ', 'emitterstrength', 0.0).to_s
            value = nil
            state = handle_operation2("Emitter Strength error:\n#{expression}"){
                value = eval(expression, cbinding)
            }
            #~ return false unless state
            next unless value.is_a?(Numeric)
            next if value.zero?
            # TODO: need to check type here.
            #address = grp.get_attribute('SPOBJ', 'body', 0).to_i
            #next if address.zero?
            #body = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(address) : Fiddle::Pointer.new(address)
            cc = grp.get_attribute('SPOBJ', 'emit_continuous_collision_mode', false)
            state = handle_operation2('Emitter Copying Group error:'){
                emitGroup(grp, nil, value, nil, nil, cc) if grp.valid?
            }
            #~ return false unless state
        }
        @dyingObjects.each { |grp, last_end, life_start, life_time|
            next if @@frame < last_end
            destroyTempObject(grp) if grp.valid?
            @dyingObjects.delete([grp, last_end, life_start, life_time])
            if @tempObjects.include?(grp)
              grp.erase! if grp.valid?
              @tempObjects.delete(grp)
            else
              grp.hidden = true
              @simulationContext.unhide_on_end << grp
            end
        }
        @controlledJoints.each { |joint|
            $curEvalGroup = joint
            expression = joint.get_attribute('SPJOINT', 'Controller', nil)
            value = nil
            if expression
                begin
                  value = eval(expression, cbinding)
                rescue Exception => e
                  puts "Exception in Joint Controller:\nExpression:\n  #{expression}\nException:\n  #{e}\n\n"
                  value = nil
                end
                #~ return false unless state
            end
            address = joint.get_attribute('SPJOINT', 'jointPtr', 0).to_i
            next if address.zero?
            joint_ptr = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(address) : Fiddle::Pointer.new(address)
            case joint.get_attribute('SPJOINT', 'type', nil)
            when 'hinge', 'servo'
                next unless value.is_a?(Numeric)
                MSketchyPhysics3::NewtonServer.setJointRotation(joint_ptr, [value].pack('f*'))
            when 'piston', 'slider'
                next unless value.is_a?(Numeric)
                MSketchyPhysics3::NewtonServer.setJointPosition(joint_ptr, [value].pack('f*'))
            when 'motor'
                next unless value.is_a?(Numeric)
                maxAccel = joint.get_attribute('SPJOINT', 'maxAccel', 0)
                accel = value*maxAccel
                MSketchyPhysics3::NewtonServer.setJointAccel(joint_ptr, [accel].pack('f*'))
            when 'gyro'
                next unless value.is_a?(Array) or value.is_a?(Geom::Point3d) or value.is_a?(Geom::Vector3d)
                MSketchyPhysics3::NewtonServer.setGyroPinDir(joint_ptr, value.to_a.pack('f*'))
            end
        }
        true
    end

    def oldupdateControlledJoints
        frame = @@frame
        @controlledJoints.each { |joint|
            controller = joint.get_attribute('SPJOINT', 'controller', '')
            value = nil
            if controller.index('oscillator')
                vals = controller.split(',')
                rate = vals[1].to_f
                inc = (2*3.141592)/rate
                pos = Math.sin(inc*(@@frame))
                MSketchyPhysics3.control_sliders[controller].value = (pos/2.0)+0.5
                value = MSketchyPhysics3.control_sliders[controller].value
            else
                #value = eval(controller, binding)
                value = MSketchyPhysics3.control_sliders[controller].value
            end
            raise 'Controller failure' unless value
            address = joint.get_attribute('SPJOINT', 'jointPtr', 0).to_i
            next if address.zero?
            joint_ptr = RUBY_VERSION =~ /1.8/ ? DL::PtrData.new(address) : Fiddle::Pointer.new(address)
            case joint.get_attribute('SPJOINT', 'type', nil)
            when 'oscillator'
                rate = joint.get_attribute('SPJOINT', 'rate', 100.0)
                rate /= value
                inc = (2*Math::PI)/rate
                pos = Math.sin(inc*(@@frame))
                MSketchyPhysics3::NewtonServer.setJointPosition(joint_ptr, [pos].pack('f*'))
            when 'servo', 'hinge'
                MSketchyPhysics3::NewtonServer.setJointRotation(joint_ptr, [value].pack('f*'))
            when 'piston', 'slider'
                MSketchyPhysics3::NewtonServer.setJointPosition(joint_ptr,[value].pack('f*'))
            when 'motor'
                maxAccel = joint.get_attribute('SPJOINT', 'maxAccel', 0)
                accel = value*maxAccel
                MSketchyPhysics3::NewtonServer.setJointAccel(joint_ptr, [accel].pack('f*'))
            end
        }
    end

    def setupCameras
        model = Sketchup.active_model
        camera = model.active_view.camera
        @savedCameraPosition = Sketchup::Camera.new(camera.eye, camera.target, camera.up, camera.perspective?, camera.fov)
        desc = model.pages.selected_page.description.downcase if model.pages.selected_page
        return unless desc
        sentences = desc.split('.')
        sentences.each { |l|
            words = l.split(' ')
            if words[0] == 'camera'
                @cameraTarget = findGroupNamed(words[2]) if words[1] == 'track'
                @cameraParent = findGroupNamed(words[2]) if words[1] == 'follow'
            end
        }
    end

    def nextFrame_standard(view)
        return false if @deactivate_called
        activate_standard(false)
        # Handle simulation play/pause events.
        if @@bPause
            unless @pause_updated
                t = Time.now
                @_time[:sim] += t - @_time[:last]
                @_fps[:change] += t - @_fps[:last]
                @pause_updated = true
            end
            view.show_frame
            return true
        end
        if @pause_updated
            t = Time.now
            @_time[:last] = t
            @_fps[:last] = t
            @pause_updated = false
        end
        # Call onPreFrame, before update takes place.
        state = handle_operation('onPreFrame error:'){
          @simulationContext.doPreFrame
        }
        return false unless state
        # Call onUpdate, just before update takes place.
        state = updateControlledJoints
        return false unless state
        # Apply pick and drag force
        if @pickedBody and @pickedBody.valid? and $sketchyphysics_version_loaded.to_f > 3.2
            @simulationContext.applyPickAndDragForce(@CursorMagnetBody, @attachPointWithScale, @attachWorldLocation, 100, 16)
        end
        # Update Newton
        MSketchyPhysics3::NewtonServer.requestUpdate(@frameRate)
        return false unless SketchyPhysicsClient.active?
        # Camera follow
        cameraPreMoveOffset = view.camera.eye-@cameraParent.bounds.center if @cameraParent
        # Fetch positions for all moving objects.
        if RUBY_VERSION =~ /1.8/
          dat = (0.chr*4*16).to_ptr
        else
          dat = 0.chr*4*16
        end
        outstr = ''
        while(id = MSketchyPhysics3::NewtonServer.fetchSingleUpdate(dat)) != 0xffffff
            matrix = RUBY_VERSION =~ /1.8/ ? dat.to_a('F', 16) : dat.unpack('F*')
            instance = @DynamicObjectList[id]
            if instance && instance.valid?
                dest = Geom::Transformation.new(matrix.to_a)
                # Reapply scaling.
                scale = instance.get_attribute('SPOBJ', 'savedScale', nil)
                if scale
                  upscale = Geom::Transformation.new(scale)
                  dest = dest*upscale
                end
                if $sketchyViewerDialog
                    # Converts from inches to meters.
                    mat = dest*Geom::Transformation.scaling(1/39.3700787401575)
                    mat = mat.to_a
                    mat[12] = mat[12]/39.3700787401575
                    mat[13] = mat[13]/39.3700787401575
                    mat[14] = mat[14]/39.3700787401575
                    outstr += 'x=g_nameToTransform["SV' + instance.entityID.to_s+'"];'
                    outstr += 'if(x!=null) g_nameToTransform["SV'+instance.entityID.to_s+'"].localMatrix='+[mat[0,4],mat[4,4],mat[8,4],mat[12,4]].inspect+';'
                end
                instance.move! dest
                if $bSPDoRecord
                    matrix = dest.to_a
                    cd = MSketchyPhysics3.get_definition(instance)
                    orig = @@origAxis[cd.entityID]
                    matrix[12..14] = orig.transform(dest).to_a if orig
                    @recordSamples[id] ||= []
                    @recordSamples[id][@@frame] = matrix
                end
            end
        end
        $sketchyViewerDialog.execute_script(outstr) if $sketchyViewerDialog
        # Update camera
        if @cameraTarget and @cameraTarget.valid?
            camera = view.camera
            camera.set(camera.eye, @cameraTarget.bounds.center, Geom::Vector3d.new(0, 0, 1))
        else
            @cameraTarget = nil
        end
        if @cameraParent and @cameraParent.valid?
            camera = view.camera
            dest = @cameraParent.bounds.center + cameraPreMoveOffset
            camera.set(dest, dest+camera.direction, Geom::Vector3d.new(0, 0, 1))
        else
            @cameraParent = nil
        end
        # Call onPostFrame, after update takes place.
        state = handle_operation('onPostFrame or onUntouch error:'){
          @simulationContext.doPostFrame
        }
        return false unless state
        if $bSPDoRecord
          cam = view.camera
          @recordCamera[@@frame] = [cam.eye.to_a, cam.target.to_a, cam.up.to_a, cam.fov]
        end
        # Update FPS
        if @frame % @_fps[:update_rate] == 0
            @_fps[:change] += Time.now - @_fps[:last]
            @_fps[:val] = ( @_fps[:change] == 0 ? 0 : (@_fps[:update_rate] / @_fps[:change]).round )
            @_fps[:last] = Time.now
            @_fps[:change] = 0
        end
        update_status_text
        # Increment frame
        @@frame += 1
        @frame = @@frame
        view.show_frame
        true
    rescue Exception => e
        puts "nextFrame Error: #{e}\n#{e.backtrace}"
        SketchyPhysicsClient.safePhysicsReset
    end

    def nextFrame(view)
      nextFrame_standard(view)
    end

    # This method is used by old LazyScript. Although it wasn't included in SP,
    # but adding this prevents many errors.
    def updateDebugFPS(frame)
    end

    def getExtents
      if Sketchup.version.to_i > 6
        Sketchup.active_model.entities.each { |ent|
          @bb.add(ent.bounds)
        }
      end
      @bb
    end

    def stop
      @bWasStopped = true
      Sketchup.active_model.active_view.show_frame
    end

    def cursorPos
        [@mouseX, @mouseY]
    end

    def onMouseEnter(view)
        @mouse_enter = true
        #focus_control
    end

    def onMouseLeave(view)
        @mouse_enter = false
    end

    def suspend(view)
    end

    def resume(view)
      view.animation = self
      view.show_frame
    end

    def getMenu(menu)
        ph = Sketchup.active_model.active_view.pick_helper
        ph.do_pick @mouseX, @mouseY
        ent = ph.best_picked
        return unless ent.is_a?(Sketchup::Group) or ent.is_a?(Sketchup::ComponentInstance)
        Sketchup.active_model.selection.add(ent)
        menu.add_item('Camera Track'){
            @cameraTarget = ent
            focus_control
        }
        menu.add_item('Camera Follow'){
            @cameraParent = ent
            focus_control
        }
        menu.add_item('Camera Clear'){
            @cameraTarget = nil
            @cameraParent = nil
            focus_control
        }
        #menu.add_item('Copy Body'){ copyBody(ent) }
    end

    def onMButtonDown(flags, x, y, view)
        ph = view.pick_helper
        ph.do_pick x,y
        ent = ph.best_picked
        return unless ent.is_a?(Sketchup::Group) or ent.is_a?(Sketchup::ComponentInstance)
        @cameraTarget = ent
        #focus_control
    end

    #def onMButtonUp(flags, x, y, view)
        #focus_control
    #end

    #def onMButtonDoubleClick(flags, x, y, view)
        #focus_control
    #end

    def onRButtonDown(flags, x, y, view)
        ph = view.pick_helper
        ph.do_pick x,y
        ent = ph.best_picked
        focus_control
    end

    def onRButtonUp(flags, x, y, view)
        ph = view.pick_helper
        ph.do_pick x,y
        ent = ph.best_picked
        focus_control
    end

    def onRButtonDoubleClick(flags, x, y, view)
        focus_control
    end

    def onLButtonDoubleClick(flags, x, y, view)
        ph = view.pick_helper
        ph.do_pick x,y
        ent = ph.best_picked
        return unless ent.is_a?(Sketchup::Group) or ent.is_a?(Sketchup::ComponentInstance)
        state = handle_operation('onDoubleClick error:'){
            @simulationContext.doOnMouse(:doubleclick, ent, x, y)
        }
        return unless state
        if MSketchyPhysics3.getKeyState(VK_LSHIFT)
            ip = view.inputpoint(x,y)
            #copyBody(ent)
        else
            #~ direction = ent.transformation.origin-view.camera.eye
            #~ direction.normalize!
            #~ direction[0] *= 3.0
            #~ direction[1] *= 3.0
            #~ direction[2] = 15.0
            #~ kick = direction
            #~ body = findBodyWithID(ent.entityID)
            #~ MSketchyPhysics3::NewtonServer.addImpulse(body, kick.to_a.pack('f*'), ent.transformation.origin.to_a.pack('f*')) if body
        end
        focus_control
    end

    def onLButtonDown(flags, x, y, view)
        return false if @deactivate_called
        model = Sketchup.active_model
        ph = view.pick_helper
        ph.do_pick x,y
        ent = ph.best_picked
        onLButtonUp(flags, x, y, view) if @pickedBody
        if ent.is_a?(Sketchup::Group) or ent.is_a?(Sketchup::ComponentInstance)
            model.selection.clear
            @clicked_body = ent
            state = handle_operation('onClick error:'){
                @simulationContext.doOnMouse(:click, @clicked_body, x, y)
            }
            return unless state
            # Use raytest as its more accurate than inputpoint.
            ip = view.inputpoint x,y
            deepest = ph.leaf_at(0)
            if deepest.is_a?(Sketchup::ConstructionPoint)
              pos = deepest.position.transform(ph.transformation_at(0))
            else
              pos = ip.position
              res = view.model.raytest( view.pickray(x,y) )
              pos = res[0] if res and res[1][0] == ent
            end

            if @pick_drag_enabled
                gd = MSketchyPhysics3.get_entities(ent).parent
                @DynamicObjectList.each_index { |doi|
                    next if @DynamicObjectList[doi] != ent
                    @CursorMagnetBody = @DynamicObjectBodyRef[doi]
                    # Transform input point into component space.
                    #ip = view.inputpoint x,y
                    #cdbounds = MSketchyPhysics3.get_entities(@pickedBody)[0].parent.bounds
                    #dsize = cdbounds.max - cdbounds.min
                    #cmass = Geom::Point3d.new(dsize.to_a)
                    #cmass.x/=2; cmass.y/=2; cmass.z/=2;
                    #pcenter = Geom::Point3d.new(dsize.y/2, dsize.x/2, dsize.z/2)
                    #xlate = Geom::Transformation.new(pcenter).inverse
                    tra = ent.transformation
                    flip = (tra.xaxis*tra.yaxis)%tra.zaxis < 0 ? -1 : 1
                    @attachPoint = pos.transform(tra.inverse)
                    @attachPointWithScale = @attachPoint.clone
                    s = [
                        X_AXIS.transform(tra).length,
                        Y_AXIS.transform(tra).length,
                        Z_AXIS.transform(tra).length * flip
                    ]
                    for i in 0..2; @attachPointWithScale[i] *= s[i] end
                    @attachWorldLocation = pos # Used to calc movement planes.
                    @magnetLocation = pos
                    newton = MSketchyPhysics3::NewtonServer
                    @orig_force_callback = newton.newtonBodyGetForceAndTorqueCallback(@CursorMagnetBody)
                    if $sketchyphysics_version_loaded.to_f > 3.2
                      newton.newtonBodySetForceAndTorqueCallback(@CursorMagnetBody, newton::TEMP_FORCE_CALLBACK)
                    else
                      MSketchyPhysics3::NewtonServer.bodySetMagnet(@CursorMagnetBody, @CursorMagnet, @attachPointWithScale.to_a.pack('f*'))
                    end
                    break
                }
                if @CursorMagnetBody
                  @pickedBody = ent
                  model.selection.add(ent)
                  @last_drag_frame = @frame
                end
            end
            if $sketchyphysics_version_loaded.to_f < 3.3
              onMouseMove(flags, x, y, view) # force magnet location to update.
            end
        end
        focus_control
    end

    def onLButtonUp(flags, x, y, view)
        return false if @deactivate_called
        if @clicked_body
            state = handle_operation('onUnclick error:'){
                @simulationContext.doOnMouse(:unclick, @clicked_body, x, y) if @clicked_body.valid?
            }
            @clicked_body = nil
            return unless state
        end
        @pickedBody = nil
        @attachPoint = nil
        @attachPointWithScale = nil
        @attachWorldLocation = nil
        @magnetLocation = nil
        if @CursorMagnetBody
            if $sketchyphysics_version_loaded.to_f > 3.2
              MSketchyPhysics3::NewtonServer.newtonBodySetForceAndTorqueCallback(@CursorMagnetBody, @orig_force_callback)
            else
              MSketchyPhysics3::NewtonServer.bodySetMagnet(@CursorMagnetBody, nil, nil)
            end
            @CursorMagnetBody = nil
            Sketchup.active_model.selection.clear
        end
        focus_control
    end

    def onMouseMove(flags, x, y, view)
        return false if @deactivate_called
        @mouseX = x
        @mouseY = y
        return unless @CursorMagnetBody
        ip = Sketchup::InputPoint.new
        ip.pick(view, x, y)
        pos = ip.position
        return unless ip.valid?
        if @pickedBody and @pickedBody.valid?
            state = handle_operation('onDrag error:'){
                @simulationContext.doOnMouse(:drag, @pickedBody, x, y) if @last_drag_frame != @frame
            }
            @last_drag_frame = @frame
            return unless state
            # Project the input point on a plane described by our normal and center.
            #~ line = [view.camera.eye, pos]
            #~ plane = [@attachWorldLocation, getKeyState(VK_LSHIFT) ? view.camera.zaxis : Z_AXIS]
            #~ @attachWorldLocation = Geom.intersect_line_plane(line, plane)

            cam = view.camera
            line = [cam.eye, pos]
            if getKeyState(VK_LSHIFT)
                normal = view.camera.zaxis
                normal.z = 0
                normal.normalize!
            else
                normal = Z_AXIS
            end
            plane = [@attachWorldLocation, normal]
            vector = cam.eye.vector_to(pos)
            theta = vector.angle_between(normal).radians
            if (90 - theta).abs > 1
                pt = Geom.intersect_line_plane(line, plane)
                v = cam.eye.vector_to(pt)
                if cam.zaxis.angle_between(v).radians < 90
                  @attachWorldLocation = pt
                  @magnetLocation = pt
                end
            end

            if @CursorMagnet and $sketchyphysics_version_loaded.to_f < 3.3
                MSketchyPhysics3::NewtonServer.magnetMove(@CursorMagnet, @attachWorldLocation.to_a.pack('f*'))
            end
        end
    end

    def draw_standard(view)
        @bb.clear
        if @pickedBody && @pickedBody.valid?
            pt1 = @attachPoint.transform(@pickedBody.transformation)
            pt2 = @attachWorldLocation
            @bb.add(pt1, pt2)
            view.line_width = @drag[:line_width]
            view.line_stipple = @drag[:line_stipple]
            view.drawing_color = @drag[:line_color]
            view.draw_line(pt1, pt2)
            view.line_stipple = ''
            view.draw_points(pt1, @drag[:point_size], @drag[:point_style], @drag[:point_color])
            if getKeyState(VK_LSHIFT)
                view.drawing_color = 'blue'
                view.line_width = 2
                view.line_stipple = '-'
                tp = @attachWorldLocation.clone
                tp.z = 0
                @bb.add(tp)
                view.draw_line(tp, @attachWorldLocation)
            end
        end
        if @bWasStopped
            view.animation = self
            @bWasStopped = false
        end
        return unless @simulationContext
        # Draw queued data.
        @simulationContext.drawQueue.each { |data|
            view.drawing_color = data[2]
            view.line_width = data[3]
            view.line_stipple = data[4]
            if data[5] == 0 # 2D
                view.draw2d(data[0], data[1])
            else # 3D
                @bb.add(data[1])
                if data[0] == GL_POINTS
                    view.draw_points(data[1], data[3], 2, data[2])
                    next
                end
                view.draw(data[0], data[1])
            end
        }
        @simulationContext.pointsQueue.each{ |points, size, style, color, width, stipple|
            view.line_width = width
            view.line_stipple = stipple
            @bb.add(points)
            view.draw_points(points, size, style, color)
        }
        # Call onDraw event
        view.drawing_color = 'black'
        view.line_width = 1
        view.line_stipple = ''
        state = handle_operation('onDraw error:'){
            @simulationContext.doOnDraw(view, @bb)
        }
        return unless state
    end

    def draw(view)
      draw_standard(view)
    end

    def onSetCursor
        UI.set_cursor(@cursor_id)
    end

    def onKeyDown(key, rpt, flags, view)
        @ctrlDown = true if key == COPY_MODIFIER_KEY && rpt == 1
        @shiftDown = true if key == CONSTRAIN_MODIFIER_KEY && rpt == 1
    end

    def onKeyUp(key, rpt, flags, view)
        @ctrlDown = false if key == COPY_MODIFIER_KEY
        @shiftDown = false if key == CONSTRAIN_MODIFIER_KEY
    end

    def checkModelUnits
        manager = Sketchup.active_model.options
        provider = manager[3]
        puts provider.name if $debug
        provider['SuppressUnitsDisplay'] = true
        provider['LengthFormat'] = 0
    end

    def resetSimulation_standard
        deactivate(nil)
    end

    def resetSimulation
      resetSimulation_standard
    end

    def self.startphysics
        self.physicsStart
    end

    # Start the physics simulation
    # @return [Boolean] success
    def self.physicsStart
        return false if $sketchyPhysicsToolInstance
        if SketchyReplay::SketchyReplay.activeInstance
          SketchyReplay::SketchyReplay.activeInstance.rewind
        end
        SketchyPhysics.checkVersion
        initDirectInput
        SketchyPhysicsClient.new
        Sketchup.active_model.select_tool $sketchyPhysicsToolInstance
        Sketchup.active_model.active_view.animation = $sketchyPhysicsToolInstance
        $sketchyPhysicsToolInstance ? true : false
    end

    def self.physicsTogglePlay
        if $sketchyPhysicsToolInstance
            @@bPause = !@@bPause
        else
            startphysics
            @@bPause = false
        end
    end

    # Added because some prior models modify SP content which causes crash.
    def self.safePhysicsReset
        return false unless $sketchyPhysicsToolInstance
        Sketchup.active_model.select_tool nil
        true
    end

    def self.physicsReset
        safePhysicsReset
    end

    def self.physicsRecord
        if @bDoRecord == true
            @@bPause = true
            msg = "Recorded #{@@frame} frames. Save animation? Press Cancel to continue recording."
            result = UI.messagebox(msg, MB_YESNOCANCEL, 'Save Animation')
            case result
            when 6 #yes
                physicsReset
                # Compress and embed animation
            when 7 #no
                physicsReset
            when 2 #cancel
                return
            end
        end
        @bDoRecord = true
        physicsTogglePlay
    end

    def self.paused?
        return false unless $sketchyPhysicsToolInstance
        @@bPause
    end

    def self.active?
        $sketchyPhysicsToolInstance ? true : false
    end

    def self.instance
        $sketchyPhysicsToolInstance
    end

end # class SketchyPhysicsClient
end # module MSketchyPhysics3
