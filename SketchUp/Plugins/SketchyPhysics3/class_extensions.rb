require 'sketchup.rb'

# SP doesn't depend on such operation, but this allows prior scripted models
# to operate in SP 3.4. Such change will not affect plugins, but it may
# confuse a plugin developer.
#~ include Math

# SP itself no longer depends on API adding methods, but some prior scripted
# models use them a lot. Such change will not affect plugins, but it may
# confuse a plugin developer.

class Sketchup::Group

  def definition
    return self.entities.parent if Sketchup.version.to_i == 14
    return self.model.definitions.find {|d|
      d.group? && d.instances.include?(self)
    }
  end if Sketchup.version.to_i <= 14

end # class Sketchup::Group

class Sketchup::ComponentInstance

  def entities
    self.definition.entities
  end unless Sketchup::ComponentInstance.method_defined?(:entities)

end # class Sketchup::ComponentInstance

module MSketchyPhysics3

  @unique_objects = {}

  def register_unique_object(id, ent)
    @unique_objects[id] = ent
  end

  def update_unique_objects
    Sketchup.active_model.definitions.each{ |cd|
      cd.instances.each { |ci|
        id = ci.get_attribute('__uniqueid', 'id', nil)
        @unique_objects[id] = ci if id
      }
    }
  end

  def find_unique_object(id)
    ent = @unique_objects[id]
    unless ent
      update_unique_objects
      ent = @unique_objects[id]
    end
    ent
  end

  class << self

    def clear_unique_objects
      @unique_objects.clear
    end

    # Return a (hopefully) unique and perm ID for a given group.
    def get_unique_id(grp)
      id = grp.get_attribute('__uniqueid', 'id', nil)
      unless id
        id = rand()
        grp.set_attribute('__uniqueid', 'id', id)
        register_unique_object(id, grp)
        find_unique_object(id)
      end
      id
    end

    # Get group/component definition.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] instance
    # @return [Sketchup::ComponentDefinition] if successful
    def get_definition(instance)
      if instance.is_a?(Sketchup::ComponentInstance)
        return instance.definition
      elsif instance.is_a?(Sketchup::Group)
        v = Sketchup.version.to_i
        return instance.definition if v > 14
        return instance.entities.parent if v == 14
        return instance.model.definitions.find {|d|
        d.group? && d.instances.include?(instance)
      }
      else
        raise(TypeError, "Expected Sketchup::Group or Sketchup::ComponentInstance, but got #{instance.class.name} !",caller)
      end
    end

    # Get group/component entities
    def get_entities(ent)
      case ent
      when Sketchup::Group, Sketchup::ComponentDefinition
        ent.entities
      when Sketchup::ComponentInstance
        ent.definition.entities
      else
        raise ArgumentError, "Expected group or a component, but got #{ent.class}."
      end
    end

  end # proxy class


  module Transformation

    module_function

    def get_scaling(tra)
      unless tra.is_a?(Geom::Transformation)
        raise ArgumentError, "Expected Geom::Transformation, but got #{tra.class}."
      end
      [ (Geom::Vector3d.new(1.0,0,0).transform!(self)).length,
        (Geom::Vector3d.new(0,1.0,0).transform!(self)).length,
        (Geom::Vector3d.new(0,0,1.0).transform!(self)).length]
    end

    def unscaled(tra)
      unless tra.is_a?(Geom::Transformation)
        raise ArgumentError, "Expected Geom::Transformation, but got #{tra.class}."
      end
      Geom::Transformation.new(tra.xaxis, tra.yaxis, tra.zaxis, tra.origin)
    end

  end # module Transformation


  module Group

    module_function

    def set_ignore(grp, flag)
      grp.set_attribute('SPOBJ', 'ignore', flag)
    end

    def get_ignore(grp)
      grp.get_attribute('SPOBJ', 'ignore', false)
    end

    def set_shape(grp, shape)
      if %w(convexhull2 compound2 staticmesh2).inlcude?(shape)
        grp.set_attribute('SPOBJ', 'advancedShape', shape)
        grp.set_attribute('SPOBJ', 'shape', nil)
      else
        grp.set_attribute('SPOBJ', 'advancedShape', nil)
        grp.set_attribute('SPOBJ', 'shape', shape)
      end
    end

    def get_shape(grp)
      shape = grp.get_attribute('SPOBJ', 'shape', nil)
      grp.get_attribute('SPOBJ', 'advancedShape', nil) unless shape
    end

    def contains?(grp, ent)
      grp.entities.each { |e|
        return true if e == ent
        next unless e.is_a?(Sketchup::Group)
        return true if contains?(e, ent)
      }
      false
    end

    def create_collision(grp, world, xform)
      return if get_ignore(grp)
      # Find the real size of the bounding box and offset to center.
      bb = MSketchyPhysics3.get_definition(grp).bounds
      scale = MSketchyPhysics3::Transformation.get_scaling(xform)
      size = [bb.width*scale[0], bb.height*scale[1], bb.depth*scale[2]]
      center = [bb.center.x*scale[0], bb.center.y*scale[1], bb.center.z*scale[2]]

      noscale = MSketchyPhysics3::Transformation.unscaled(xform)
      center = Geom::Transformation.new(center)
      finalXform = noscale*center

      shape = get_shape(grp)
      col =  MSketchyPhysics3::NewtonServer.createCollision(shape, size.pack('f*'), finalXform.to_a.pack('f*'), verts.to_a.pack('f*')) # if convexhull
      #~ col=nil
      #~ case shape
        #~ when "box"
          #~ col=Newton.newtonCreateBox(world,size[0],size[1],size[2],finalXform.to_a.pack('f*'))
        #~ when "sphere"
          #~ col=Newton.newtonCreateSphere(world,size[0],size[1],size[2],finalXform.to_a.pack('f*'))
        #~ when "cylinder"
          #~ col=Newton.newtonCreateCylinder(world,size[0],size[1],size[2],finalXform.to_a.pack('f*'))
        #~ when "cone"
          #~ col=Newton.newtonCreateCone(world,size[0],size[1],size[2],finalXform.to_a.pack('f*'))
        #~ when "capsule"
          #~ col=Newton.newtonCreateCapsule(world,size[0],size[1],size[2],finalXform.to_a.pack('f*'))
        #~ when "chamfer"
          #~ col=Newton.newtonCreateChamfer(world,size[0],size[1],size[2],finalXform.to_a.pack('f*'))
      #~ end
      col
    end

    def find_shapes(grp, parentXform = Geom::Transformation.new)
      return [] if get_ignore(grp)
      xform = parentXform*grp.transformation
      sa = []
      shape = get_shape(grp)
      if shape
        sa << [shape, xform]
        # puts "Collision #{shape} at #{xform.to_a.inspect}"
      else
        grp.entities.each { |ent|
          if ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
            sa << find_shapes(ent, xform)
          end
        }
      end
      if sa.empty?
        sa << ['default', xform]
        # puts "Default collision at #{xform.to_a.inspect}"
      end
      return sa.flatten
    end

    def get_shapes(grp)
      return [] if get_ignore(grp)
      sa = []
      if get_shape(grp)
        sa << grp
      else
        grp.entities.each { |ent|
          if ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
            sa << get_shapes(ent)
          end
        }
      end
      if sa.empty?
        sa << grp
      end
      return sa.flatten
    end

    def get_joints(grp)
      MSketchyPhysics3.get_entities(grp).select { |ent|
        ent.is_a?(Sketchup::Group) && is_joint?(ent)
      }
    end

    def is_body?(grp)
      grp.parent.is_a?(Sketchup::Model)
    end

    def is_joint?(grp)
      grp.get_attribute('SPJOINT', 'name', nil) ? true : false
    end

    def get_connections(grp)
      grp.get_attribute('SPOBJ', 'parentJoints', [])
    end

    def connect(grp, joint)
      name = joint.get_attribute('SPJOINT', 'name', nil)
      all = grp.get_attribute('SPOBJ', 'parentJoints', [])
      all << name
      grp.set_attribute('SPOBJ', 'parentJoints', all)
    end

    def copy(grp, pos = nil, lifetime = 0)
      return unless $sketchyPhysicsToolInstance
      # body = DL::PtrData.new(grp.get_attribute('SPOBJ', 'body', nil))
      # return unless body
      pos = Geom::Transformation.new(pos) if pos
      $sketchyPhysicsToolInstance.copyBody(grp, pos, lifetime)
    end

  end # module Group
end # module MSketchyPhysics3
