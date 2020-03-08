require 'sketchup.rb'

module MSketchyPhysics3

  CURSORS = {
    :select             => 0,
    :select_plus        => 0,
    :select_plus_minus  => 0,
    :hand               => 671,
    :target             => 0
  }

  # Create cursors
  dir = File.dirname(__FILE__)
  path = File.join(dir, 'images/cursors')
    names = [:select, :select_plus, :select_plus_minus]
    names.each { |name|
    CURSORS[name] = UI.create_cursor(File.join(path, name.to_s + '.png'), 5, 12)
  }
  CURSORS[:target] = UI.create_cursor(File.join(path, 'target.png'), 15, 15)

  class << self

    # Clamp value between min and max.
    # @param [Numeric] value
    # @param [Numeric, NilClass] min Pass +nil+ to have no min limit.
    # @param [Numeric, NilClass] max Pass +nil+ to have no max limit.
    # @return [Numeric]
    def self.clamp(value, min, max)
      value = min if min and value < min
      value = max if max and value > max
      value
    end

    # Get points on a 2D circle.
    # @param [Array<Numeric>] origin
    # @param [Numeric] radius
    # @param [Fixnum] num_seg Number of segments.
    # @param [Numeric] rot_angle Rotate angle in degrees.
    # @return [Array<Array<Numeric>>] An array of points on circle.
    def self.points_on_circle2d(origin, radius, num_seg = 16, rot_angle = 0)
      ra = rot_angle.degrees
      offset = Math::PI*2/num_seg.to_i
      pts = []
      for n in 0...num_seg.to_i
        angle = ra + (n*offset)
        x = Math.cos(angle)*radius
        y = Math.sin(angle)*radius
        pts << [x + origin[0], y + origin[1]]
      end
      pts
    end

    # Get points on a 3D circle.
    # @param [Array<Numeric>, Geom::Point3d] origin
    # @param [Array<Numeric>, Geom::Vector3d] normal
    # @param [Numeric] radius
    # @param [Fixnum] num_seg Number of segments.
    # @param [Numeric] rot_angle Rotate angle in degrees.
    # @return [Array<Geom::Point3d>] An array of points on circle.
    def self.points_on_circle3d(origin, radius, normal = [0,0,1], num_seg = 16, rot_angle = 0)
      # Get the x and y axes
      origin = Geom::Point3d.new(origin)
      axes = Geom::Vector3d.new(normal).axes
      xaxis = axes[0]
      yaxis = axes[1]
      xaxis.length = radius
      yaxis.length = radius
      # Compute points
      ra = rot_angle.degrees
      offset = Math::PI*2/num_seg.to_i
      pts = []
      for n in 0...num_seg.to_i
        angle = ra + (n*offset)
        cosa = Math.cos(angle)
        sina = Math.sin(angle)
        vec = Geom::Vector3d.linear_combination(cosa, xaxis, sina, yaxis)
        pts << origin + vec
      end
      pts
    end

    # Get numeric value sign.
    # @param [Numeric] value
    # @return [Fixnum] -1, 0, or 1
    def sign(value)
      value.zero? ? 0 : (value > 0 ? 1 : -1)
    end

    # Scale vector.
    # @param [Array<Numeric>, Geom::Vector3d] vector
    # @param [Numeric] scale
    # @return [Geom::Vector3d]
    def scale_vector(vector, scale)
      Geom::Vector3d.new(vector[0]*scale, vector[1]*scale, vector[2]*scale)
    end

    # Get least value of the two values.
    # @param [Numeric] a
    # @param [Numeric] b
    # @return [Numeric]
    def min(a, b)
      a < b ? a : b
    end

    # Get greatest value of the two values.
    # @param [Numeric] a
    # @param [Numeric] b
    # @return [Numeric]
    def max(a, b)
      a > b ? a : b
    end

  end # class << self


def pickGroupEmbedded(x, y, view)
    ph = view.pick_helper
    num = ph.do_pick x,y
    item = nil
    path = ph.path_at(1)
    return item unless path
    path.length.downto(0){ |i|
        if (path[i].is_a?(Sketchup::Group) &&
            (path[i].parent.is_a?(Sketchup::Model) || path[i].get_attribute('SPJOINT', 'name', nil) != nil))
            item = path[i]
            break
        end
    }
    return item
    puts "element_at 1 #{ph.element_at(1)}"
    topGroup = ph.element_at(1)
    if topGroup.is_a?(Sketchup::Group)
        puts "topGroup xform: #{topGroup.transformation.origin}"
        xform = ph.transformation_at(1)
        puts "xform at 1: #{xform.origin}"
        xform = xform*topGroup.transformation.inverse
        puts "xform 1 inverse: #{xform.origin}"
        face = ph.picked_face
        if face.parent.is_a?(Sketchup::ComponentDefinition)
            face.parent.instances.each { |ci|
                puts ci.transformation.origin
                if ci.transformation.origin == xform.origin
                    #Sketchup.active_model.selection.clear
                    #Sketchup.active_model.selection.add ci
                    puts "Found #{ci}"
                    return ci
                end
            }
        end
    end
    puts "Found topGroup #{topGroup}"
    topGroup
end

def self.isValidContextMenuItem(selection)
    selection.each { |ent|
        return true if ent.is_a?(Sketchup::Group) or ent.is_a?(Sketchup::ComponentInstance)
    }
    false
end

def self.togglePhysicsAttribute(selection, attrib, defaultValue)
    selection.each { |ent|
        if ent.is_a?(Sketchup::Group) or ent.is_a?(Sketchup::ComponentInstance)
            bNewState = ent.get_attribute('SPOBJ', attrib, defaultValue)
            s = bNewState ? false : true
            if s
              ent.set_attribute('SPOBJ', attrib, true)
            else
              ent.delete_attribute('SPOBJ', attrib)
            end
        end
    }
end

def self.setPhysicsAttribute(sel, attrib, value)
    if sel.is_a?(Sketchup::Group) or sel.is_a?(Sketchup::ComponentInstance)
        if (value == nil || value == false || value == '')
            sel.delete_attribute('SPOBJ', attrib)
        else
            sel.set_attribute('SPOBJ', attrib, value)
        end
        return
    end
    model = Sketchup.active_model
    if Sketchup.version.to_i > 6
      model.start_operation('Set Multiple Attributes', true)
    else
      model.start_operation('Set Multiple Attributes')
    end
    sel.each { |ent|
        if ent.is_a?(Sketchup::Group) or ent.is_a?(Sketchup::ComponentInstance)
            if (value == nil || value == false || value == '')
                ent.delete_attribute('SPOBJ', attrib)
            else
                ent.set_attribute('SPOBJ', attrib, value)
            end
        end
    }
    model.commit_operation
end

def self.validate_physicsAttribute(key, defaultValue)
    selection = Sketchup.active_model.selection
    #return MF_GRAYED if not selection.single_object?
    selection.first.get_attribute('SPOBJ', key, defaultValue) ? MF_CHECKED : MF_UNCHECKED
end

def self.validate_physicsAttributeString(key, value)
    selection = Sketchup.active_model.selection
    #return MF_GRAYED if not selection.single_object?
    val = selection.first.get_attribute('SPOBJ', key, nil)
    val == value ? MF_CHECKED : MF_UNCHECKED
end

def makePhysicsCylinder(radius, depth)
    group = Sketchup.active_model.active_entities.add_group
    circle = group.entities.add_circle([0,0,0], [0,0,1], radius, 24)
    base = group.entities.add_face circle
    depth = -depth if base.normal.dot(Z_AXIS) < 0.0
    base.pushpull depth
    MSketchyPhysics3.setPhysicsAttribute(group, 'shape', 'cylinder')
    group.name = 'cylinder'
    return(group)
end

def createDefaultScene
    return # Broken!
    Sketchup.active_model.start_operation 'Create Default Physics Scene'
    MSketchyPhysics3.checkModelUnits
    cube = makePhysicsCube(Sketchup.active_model.active_entities, 1000, 1000, -20)
    cube.transform!(Geom::Transformation.new([0,0,-10]))
    MSketchyPhysics3.setPhysicsAttribute(cube, 'shape', 'staticmesh') # Change to static mesh.
    cube.set_attribute('SPOBJ', 'staticmesh', true)
    cube.name = 'staticmesh'

    cube = makePhysicsCube(Sketchup.active_model.active_entities, 12, 12, 12)
    cube.transform!(Geom::Transformation.new([-24,0,6]))

    cyl = makePhysicsCylinder(12/2, 12)
    cyl.transform!(Geom::Transformation.new([-36,-14,0]))

    grp = create_cone(Sketchup.active_model.active_entities, 6, 12, 10, 0) # rad, hei, segs, taper
    grp.set_attribute('SPOBJ', 'shape', 'cone')
    grp.transform!(Geom::Transformation.new([-24,-24,0], [0,0,1]))

    grp = create_sphere(6, 12) # last number is seg count
    grp.set_attribute('SPOBJ', 'shape', 'sphere')
    n = Geom::Vector3d.new([0,0,1])
    n.length = 12/2
    center = Geom::Point3d.new([0,0,0])+n
    grp.transform!(Geom::Transformation.new(center, n))
    grp.transform!(Geom::Transformation.new([-24,-36,0], [0,0,1]))

    Sketchup.active_model.commit_operation
end

def disconnectJoint(child, jointName)
    puts "delete #{jointName}"
    puts Sketchup.active_model.selection.first.get_attribute('SPOBJ', jointName, nil)
    Sketchup.active_model.selection.first.delete_attribute('SPOBJ', jointName)
    puts Sketchup.active_model.selection.first.get_attribute('SPOBJ', jointName, nil)
end

def putsAllAttributes
    Sketchup.active_model.definitions.each { |cd|
        cd.instances.each { |ci|
            puts ci.to_s + "={"
            if ci.attribute_dictionaries
                ci.attribute_dictionaries.each { |atd|
                    puts atd.name + ":"
                    atd.each_pair { |key, value| puts "#{key} = #{value}" }
                }
            end
            puts "}"
        }
        #get_attribute('SPOBJ', jointName, nil)
        #componentDef.attribute_dictionary('SPOBJ')
    }
end

#~ def findJoint(jointName)
    #~ joints=[]
    #~ Sketchup.active_model.definitions.each{ |cd|
        #~ cd.instances.each{|ci|
            #~ jn=ci.get_attribute('SPJOINT','name',nil)
            #~ if(jn!=nil && jn==jointName)
                #~ joints.push(ci)
            #~ end
            #~ }
        #~ }
    #~ #puts joints
    #~ Sketchup.active_model.selection.add(joints)
    #~ return joints
#~ end
#~ def disconnectAllJoints()
    #~ pn=0
    #~ while(Sketchup.active_model.selection.first.get_attribute('SPOBJ',"jointParent"+pn.to_s,nil)!=nil)
        #~ #pname="jointParent"+pn.to_s
        #~ Sketchup.active_model.selection.first.delete_attribute('SPOBJ',"jointParent"+pn.to_s)
        #~ pn=pn+1;
    #~ end
    #~ Sketchup.active_model.selection.first.set_attribute('SPOBJ',"numParents",0)
#~ end
#~ def selectAllJoints()
    #~ count=0
    #~ ent=Sketchup.active_model.selection.first
    #~ np=0 #ent.get_attribute('SPOBJ',"numParents",0)
    #~ Sketchup.active_model.selection.clear
    #~ while(np<10)
        #~ #pname="jointParent"+pn.to_s
        #~ jn=ent.get_attribute('SPOBJ',"jointParent"+np.to_s)
        #~ if(jn!=nil)
            #~ findJoint(jn)
        #~ end
        #~ np=np+1
    #~ end
#~ end

def purgeAllAnimation
    Sketchup.active_model.entities.each { |ent|
        if ent.attribute_dictionaries
            ent.attribute_dictionaries.delete('xxanimationdictionary')
            ent.attribute_dictionaries.delete('animationdictionary')
            ent.attribute_dictionaries.delete('SRPAnimation')
        end
    }
end

def self.editPhysicsSettings
    dict = Sketchup.active_model.attribute_dictionary('SPSETTINGS')
    unless dict
        setDefaultPhysicsSettings
        dict = Sketchup.active_model.attribute_dictionary('SPSETTINGS')
    end
    # Get framerate or set default.
    @frameRate = Sketchup.active_model.set_attribute('SPSETTINGS', 'framerate',
        Sketchup.active_model.get_attribute('SPSETTINGS', 'framerate', 3))
    prompts = dict.keys
    values = dict.values
    results = inputbox prompts, values, 'Physics Settings'
    if results && results != values
        0.upto(prompts.length-1) do |xx|
           dict[prompts[xx]] = results[xx]
        end
    end
end

def self.nameCurve(oldName = '')
    prompts = ['name']
    defaults = [oldName]
    input = UI.inputbox prompts, defaults, 'Curve Name.'
    if input && !input[0].empty?
        Sketchup.active_model.selection[0].curve.set_attribute('SPCURVE', 'name', input[0])
    end
end


unless file_loaded?(__FILE__)
    file_loaded(__FILE__)

    UI.add_context_menu_handler { |menu|
        selection = Sketchup.active_model.selection
        if selection[0].is_a?(Sketchup::Edge) && selection[0].curve != nil
            submenu = menu.add_submenu('SketchyPhysics')
            name = selection[0].curve.get_attribute('SPCURVE', 'name', nil)
            if name
                submenu.add_item("Curve : #{name.capitalize}"){ MSketchyPhysics3.nameCurve(name) }
            else
                submenu.add_item('Make Physics Curve'){ MSketchyPhysics3.nameCurve }
            end
        elsif MSketchyPhysics3.isValidContextMenuItem(selection)
            submenu = menu.add_submenu('SketchyPhysics')
            menu = submenu
            primList = %w(box sphere cylinder cone capsule chamfer convexhull convexhull2)
            if Sketchup.active_model.active_entities == Sketchup.active_model.entities
              primList.concat %w(compound2 staticmesh staticmesh2)
            end
            if selection.single_object?
                selected = selection.first
                tstr = 'State: '
                if selected.get_attribute('SPOBJ', 'frozen', false)
                    tstr += 'Frozen  '
                end
                if selected.get_attribute('SPOBJ', 'static', false)
                    tstr += 'Static  '
                end
                if selected.get_attribute('SPOBJ', 'ignore', false)
                    tstr += 'Ignore  '
                end
                if selected.get_attribute('SPOBJ', 'nocollison', false)
                    tstr += 'Not-Collidable'
                end
                stateSubmenu = menu.add_submenu(tstr)
                statenames = %w(ignore frozen static static_mesh show_collision no_auto_freeze magnetic no_collison)
                statenames.each { |sn|
                    attrib = sn.split('_').join('')
                    words = sn.split('_')
                    words.each { |w| w.capitalize! }
                    name = words.join(' ')
                    name = 'Not Collidable' if name == 'No Collison'
                    item = stateSubmenu.add_item(name){
                        MSketchyPhysics3.togglePhysicsAttribute(selection, attrib, false)
                    }
                    stateSubmenu.set_validation_proc(item){
                        MSketchyPhysics3.validate_physicsAttribute(attrib, false)
                    }
                }
                #item = stateSubmenu.add_item("Frozen") { MSketchyPhysics3::togglePhysicsAttribute(selection,"frozen",false) }
                #stateSubmenu.set_validation_proc(item) {MSketchyPhysics3::validate_physicsAttribute("frozen",false) }
                #item = stateSubmenu.add_item("Static") { MSketchyPhysics3::togglePhysicsAttribute(selection,"static",false) }
                #stateSubmenu.set_validation_proc(item) {MSketchyPhysics3::validate_physicsAttribute("static",false) }
                #item = stateSubmenu.add_item('ignore') { MSketchyPhysics3::togglePhysicsAttribute(selection,'ignore',false) }
                #stateSubmenu.set_validation_proc(item) {MSketchyPhysics3::validate_physicsAttribute('ignore',false) }

                #item = stateSubmenu.add_item("NoCollision") { togglePhysicsAttribute(selection,"nocollide",false) }
                #stateSubmenu.set_validation_proc(item) {validate_physicsAttribute("nocollide",false) }
                #item = stateSubmenu.add_item("EmbedGeometry") { togglePhysicsAttribute(selection,"embedgeometry",false) }
                #stateSubmenu.set_validation_proc(item) {validate_physicsAttribute("embedgeometry",false) }

                shape = selected.get_attribute('SPOBJ', 'shape', nil)
                shape = selected.get_attribute('SPOBJ', 'advancedShape', 'default') unless shape
                shapeSubmenu = submenu.add_submenu("Shape : #{shape.capitalize}")
                item = shapeSubmenu.add_item('Default'){
                  MSketchyPhysics3.setPhysicsAttribute(selection, 'shape', nil)
                  MSketchyPhysics3.setPhysicsAttribute(selection, 'advancedShape', nil)
                }
                shapeSubmenu.set_validation_proc(item){
                  e = selection.first
                  (e.get_attribute('SPOBJ', 'shape', nil).nil? and e.get_attribute('SPOBJ', 'advancedShape', nil).nil?) ? MF_CHECKED : MF_UNCHECKED
                }
                primList.each { |prim|
                    attrib = prim.split('_').join('')
                    words = prim.split('_')
                    words.each { |w| w.capitalize! }
                    name = words.join(' ')
                    item = shapeSubmenu.add_item(name){
                        if %w(convexhull2 compound2 staticmesh2).include?(attrib)
                          MSketchyPhysics3.setPhysicsAttribute(selection, 'advancedShape', attrib)
                          MSketchyPhysics3.setPhysicsAttribute(selection, 'shape', nil)
                        else
                          MSketchyPhysics3.setPhysicsAttribute(selection, 'advancedShape', nil)
                          MSketchyPhysics3.setPhysicsAttribute(selection, 'shape', attrib)
                        end
                    }
                    shapeSubmenu.set_validation_proc(item){
                        k = %w(convexhull2 compound2 staticmesh2).include?(attrib) ? 'advancedShape' : 'shape'
                        MSketchyPhysics3.validate_physicsAttributeString(k, attrib)
                    }
                }

                #~ parentSubmenu=submenu.add_submenu("  Joint connections:"+selected.get_attribute('SPOBJ',"numParents",0).to_s)
                #~ item = parentSubmenu.add_item("Set New Parent Joint") {selectParentJoint(selected)}

                #~ item = parentSubmenu.add_item("Disconnect All") { disconnectAllJoints() }
                #~ item = parentSubmenu.add_item("Select all joints") { selectAllJoints() }

                #~ pn=0
                #~ while(selected.get_attribute('SPOBJ',"jointParent"+pn.to_s,nil)!=nil)
                    #~ pname="jointParent"+pn.to_s
                    #~ #type = selected.get_attribute(jname,'type',nil)
                    #~ jsm = parentSubmenu.add_submenu("Parent:"+selected.get_attribute('SPOBJ',pname,nil).to_s)
                    #~ item = jsm.add_item("Select Joint") {}
                    #~ #puts pn
                    #~ item = jsm.add_item("Disconnect All") { disconnectAllJoints() }
                    #~ pn=pn+1
                #~ end
            else
                stateSubmenu = menu.add_submenu('Group State Change')
                stateSubmenu.add_item('Freeze'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'frozen', true)
                }
                stateSubmenu.add_item('UnFreeze'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'frozen', false)
                }
                stateSubmenu.add_item('Static'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'static', true)
                }
                stateSubmenu.add_item('Movable'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'static', false)
                }
                stateSubmenu.add_item('Ignore'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'ignore', true)
                }
                stateSubmenu.add_item('Clear Ignore Flag'){
                    MSketchyPhysics3.setPhysicsAttribute(selection,'ignore', false)
                }
                stateSubmenu.add_item('Magnetic'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'magnetic', true)
                }
                stateSubmenu.add_item('Not Magnetic'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'magnetic', false)
                }
                stateSubmenu.add_item('Auto Freeze'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'noautofreeze', false)
                }
                stateSubmenu.add_item('No Auto Freeze'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'noautofreeze', true)
                }
                stateSubmenu.add_item('Not Collidable'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'nocollison', true)
                }
                stateSubmenu.add_item('Collidable'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'nocollison', false)
                }
                stateSubmenu.add_item('Show Collision'){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'showcollision', true)
                }
                stateSubmenu.add_item("Don't Show Collision"){
                    MSketchyPhysics3.setPhysicsAttribute(selection, 'showcollision', false)
                }
                shapeSubmenu = menu.add_submenu('Group Shape Change')
                item = shapeSubmenu.add_item('Default'){
                  MSketchyPhysics3.setPhysicsAttribute(selection, 'shape', nil)
                  MSketchyPhysics3.setPhysicsAttribute(selection, 'advancedShape', nil)
                }
                primList.each { |prim|
                    attrib = prim.split('_').join('')
                    words = prim.split('_')
                    words.each { |w| w.capitalize! }
                    name = words.join(' ')
                    item = shapeSubmenu.add_item(name){
                        if %w(convexhull2 compound2 staticmesh2).include?(attrib)
                          MSketchyPhysics3.setPhysicsAttribute(selection, 'advancedShape', attrib)
                          MSketchyPhysics3.setPhysicsAttribute(selection, 'shape', nil)
                        else
                          MSketchyPhysics3.setPhysicsAttribute(selection, 'advancedShape', nil)
                          MSketchyPhysics3.setPhysicsAttribute(selection, 'shape', attrib)
                        end
                    }
                }
            end
            # Debug
            submenu = menu.add_submenu('Debug')
            item = submenu.add_item('Readback Collision Geometry'){
                MSketchyPhysics3.togglePhysicsAttribute(selection, 'showgeometry', false)
            }
            submenu.set_validation_proc(item){
                MSketchyPhysics3.validate_physicsAttribute('showgeometry', false)
            }
            item = menu.add_item('Physics Copy'){
                Sketchup.active_model.selection.each { |ent|
                    if ent.is_a?(Sketchup::Group)
                        SketchyPhysicsClient.physicsSafeCopy
                    end
                }
            }
        end
    }
end

end # module MSketchyPhysics3
