require 'sketchup.rb'

module MSketchyPhysics3

  def embedIndexInValue(value, int)
    # Take value (float) convert to a int that is the binary equiv.
    # Mask out the bottom 4 bits the OR the index into those bits.
    [(([value].pack('f').unpack('l')[0]) & 0xfffffff0 |int )].pack('l').unpack('f')[0]
  end

  def extractEmbededIndex(value)
    return (([value].pack('f').unpack('l')[0]) & 0xf),
    [(([value].pack('f').unpack('l')[0]) & 0xfffffff0)].pack('l').unpack('f')
  end

  # Idea. extend instance to include physics info.
  # group
  #  physics
  #    type (obj or joint)
  #    id
  #    state
  #    parents
  #    getchilderen if obj the objs in group.
  #    if joint then objs connected to this group.
  class JointConnectionTool

    @@active = false

    def self.active?
      @@active
    end

    def refresh_viewport
      Sketchup.active_model.active_view.invalidate
      onSetCursor
    end

    def onMouseEnter(view)
      refresh_viewport
    end

    def resume(view)
      @ctrl_down = false
      @shift_down = false
      refresh_viewport
    end

    def updateDialog
    end

    def onSetCursor
      if RUBY_PLATFORM =~ /mswin|mingw/i
        @ctrlDown = MSketchyPhysics3.getKeyState(VK_LCONTROL)
      else
        @ctrlDown = MSketchyPhysics3.getKeyState(VK_LOPTION)
      end
      @shiftDown = MSketchyPhysics3.getKeyState(VK_LSHIFT)
      #return UI.set_cursor(634) if @ctrlDown
      #return UI.set_cursor(636) if @shiftDown
      #return UI.set_cursor(633)
      return UI.set_cursor(MSketchyPhysics3::CURSORS[:select_plus]) if @ctrlDown
      return UI.set_cursor(MSketchyPhysics3::CURSORS[:select_plus_minus]) if @shiftDown
      return UI.set_cursor(MSketchyPhysics3::CURSORS[:select])
    end

    def doSelectObject(ent)
      return if ent.nil? || @selectedObject == ent
      # puts ent.name + ": Attached to:" + ent.get_attribute('SPOBJ', 'parentname', 'nothing') + ent.get_attribute('SPOBJ', 'parentid', '')

      #~ if @ctrlDown && @shiftDown && @selectedObject != nil && ent != nil
        #~ JointConnectionTool.attach(ent,@selectedObject)
        #~ ent = @selectedObject
      #~ end

      if @ctrlDown && !@shiftDown && @selectedObject != nil && ent != nil
        JointConnectionTool.connectJoint(@selectedObject, ent)
        ent = @selectedObject
      end
      if @shiftDown && !@ctrlDown && @selectedObject != nil && ent != nil
        disconnectJoint(@selectedObject, ent)
        ent = @selectedObject
      end
      @selectedObject = ent
      Sketchup.active_model.selection.clear()
      if @selectedObject
        @selectedIsJoint = ent.get_attribute('SPJOINT', 'name', nil) ? true : false
        if @selectedIsJoint
          @relatedObjects = findJointChildren(@selectedObject.get_attribute('SPJOINT', 'name', nil))
          Sketchup.active_model.selection.add(@selectedObject)
        else
          @relatedObjects = findObjectsJoints(@selectedObject)
          #add to selection to add clairty (if it isnt a joint due to visual bug)
          Sketchup.active_model.selection.add(@selectedObject)
        end
        #puts @relatedObjects
        #Sketchup.active_model.selection.add(@relatedObjects)
        @selectedBounds = calcBounds(@selectedObject, @selectedParent)
        @relatedBounds = []
        @relatedObjects.each { |ro|
          parent = nil
          unless ro.parent.is_a?(Sketchup::Model)
            parent = ro.parent.instances[0]
          end
          @relatedBounds << calcBounds(ro, parent)
        }
      else
        @selectedIsJoint = false
        @relatedObjects = []
      end
      updateDialog
    end

    def activate
      Sketchup.set_status_text "Click to select. Hold CTRL and click to connect. Hold SHIFT and click to disconnect."

      @@active = true

      @allJoints = {}
      @allChildren = []
      @dragging = false

      @hoverJoint = nil
      @hoverJointGroup = nil
      @hoverGroup = nil
      @selectedObject = nil
      @selectedIsJoint = false

      @dropPoint = nil
      @dropGroup = nil

      @relatedObjects = []
      @relatedBounds = []

      @ctrlDown = false
      @shiftDown = false

      Sketchup.active_model.selection.clear

      # Replace with call to inspectModel.
      if RUBY_VERSION.to_i > 6
        Sketchup.active_model.start_operation('Fix Joints', true)
      else
        Sketchup.active_model.start_operation('Fix Joints')
      end
      Sketchup.active_model.definitions.each { |cd|
        cd.instances.each { |ci|
          #~ if(ci.get_attribute('SPOBJ',"numParents",nil)!=nil)
            #~ @allChildren.push(ci)
          #~ end

          jnames = JointConnectionTool.getParentJointNames(ci)
          @allChildren.push(ci) unless jnames.empty?

          if ci.get_attribute('SPJOINT', 'name', nil)
            jname = ci.get_attribute('SPJOINT', 'name', nil)
            # Confirm joint is unique
            if ci.parent.class != Sketchup::Model && ci.parent.instances.length > 1
              puts "Warning copied joint #{ci.parent.instances.length}"
              newi = ci.parent.instances[1]
              #~ newi.make_unique
              puts "Duplicated joint. Renaming."
              # Rename joint.
              newname = ci.get_attribute('SPJOINT', 'type', nil) + newi.entityID.to_s + rand(1000).to_s
              newi.set_attribute('SPJOINT', 'name', newname)
              newi.name = newname
              #~ while(ci.parent.instances.length > 1){ |i|
                #~ ni=ci.parent.instances[i].make_unique
                #~ ni.set_attribute('SPOBJ',"numParents",0) # disconnect from any joints
                #~ puts "disconnect"
              #~ }
              #oi = ci.parent.instances[1]
              #jname = oi.get_attribute('SPJOINT', 'type', nil) + oi.entityID.to_s
              #oi.parent.instances[1].set_attribute('SPJOINT', 'name', jname)
            end
            if @allJoints[jname]
              #puts "Duplicated joint. Renaming."
              # Rename joint.
              #jname = ci.get_attribute('SPJOINT', 'type', nil) + ci.entityID.to_s
              #ci.set_attribute('SPJOINT', 'name', jname)
              #ci.name = jname
            end
            @allJoints[jname] = ci
          end
        }
      }
      Sketchup.active_model.commit_operation
      SketchyPhysics.checkVersion
    end

    def deactivate(view)
      @@active = false
      doSelectObject(nil)
      Sketchup.set_status_text('')
      view.invalidate
    end

    def draw(view)
      if @dragging
        view.line_width = 3
        view.drawing_color = @dropGroup ? 'green' : 'yellow'
        if @inputPoint != nil && @dropPoint != nil
          view.draw_line(@inputPoint.position, @dropPoint.position)
        end
      end

      view.drawing_color = @selectedIsJoint ? 'yellow' : 'green'

      if @selectedObject
        view.line_width = 3
        view.draw(GL_LINE_STRIP, @selectedBounds)
      end

      view.drawing_color = @selectedIsJoint ? 'green' : 'yellow'
      @relatedBounds.each { |rb| view.draw(GL_LINE_STRIP, rb) }

      #~ normal= @selectedObject.transformation.origin.vector_to([0,0,1].transform!(@selectedObject.transformation))
      #~ pts=sp_points_on_circle([0,0,30].transform!(@selectedObject.transformation),normal,10, 20,0)
      #~ view.draw(GL_LINE_STRIP, pts)
      #~ pts=sp_points_on_circle([0,0,-30].transform!(@selectedObject.transformation),normal,10, 20,0)
      #~ view.draw(GL_LINE_STRIP, pts)
      #~ pts=sp_points_on_circle(@selectedObject.transformation.origin,normal,10, 20,0)
      #~ view.draw(GL_LINE_STRIP, pts)
      #~ view.draw_line([0,0,-30].transform!(@selectedObject.transformation),[0,0,30].transform!(@selectedObject.transformation))
      #box=[-0.5,0.5,0.5,
      #boundingbox.corner
      #if(@selectedObject!=nil && !@relatedObjects.empty?)
      #   @relatedObjects.each{|o|
      #     view.draw_line(@selectedObject.transformation.origin,o.transformation.origin)
      #   }
      #end
      #view.draw(GL_LINE_STRIP, pts)
    end

    # My func to find the bounding box of a object so I can display it instead of SU.
    def calcBounds(grp, parent)
      xform = grp.transformation
      if parent
        #parent = findParentInstance(grp)
        xform = parent.transformation*xform
      end
      bounds = MSketchyPhysics3.get_definition(grp).bounds
      return [
        bounds.corner(0).transform!(xform),
        bounds.corner(1).transform!(xform),
        bounds.corner(3).transform!(xform),
        bounds.corner(2).transform!(xform),
        bounds.corner(0).transform!(xform),

        bounds.corner(4).transform!(xform),
        bounds.corner(5).transform!(xform),
        bounds.corner(7).transform!(xform),
        bounds.corner(6).transform!(xform),
        bounds.corner(4).transform!(xform),

        bounds.corner(6).transform!(xform),
        bounds.corner(2).transform!(xform),
        bounds.corner(3).transform!(xform),
        bounds.corner(7).transform!(xform),
        bounds.corner(5).transform!(xform),
        bounds.corner(1).transform!(xform),
      ]
      #@myBounds.transform!(grp.transformation)
    end

    def getExtents
      bb = Geom::BoundingBox.new
      if @inputPoint
        bb.add @inputPoint.position
        bb.add @inputPoint.position
      end
    end

    # This is called followed directly by onRButtonDown
    def getMenu(menu)
    end

    def onCancel(reason, menu)
    end

    def onKeyDown(key, rpt, flags, view)
      @ctrlDown = true if(key == COPY_MODIFIER_KEY && rpt == 1 )
      @shiftDown = true if( key == CONSTRAIN_MODIFIER_KEY && rpt == 1 )
      refresh_viewport
    end

    def onKeyUp(key, rpt, flags, view)
      @ctrlDown = false if key == COPY_MODIFIER_KEY
      @shiftDown = false if key == CONSTRAIN_MODIFIER_KEY
      refresh_viewport
    end

    def pickEmbeddedJoint(x, y, view)
      ph = view.pick_helper
      num = ph.do_pick x,y
      item = nil
      path = ph.path_at(1)
      return item unless path
      path.length.downto(0) { |i|
        if(path[i].is_a?(Sketchup::Group) &&
          (path[i].parent.is_a?(Sketchup::Model) || path[i].get_attribute('SPJOINT', 'name', nil) != nil))
          item = path[i]
          #puts "ParentGroup=" + item.to_s
          break
        end
      }
      item
    end

    def findJointChildren(jname)
      kids = []
      Sketchup.active_model.definitions.each { |cd|
        cd.instances.each { |ci|
          jnames = JointConnectionTool.getParentJointNames(ci)
          kids.push(ci) if jnames.include?(jname) && ci.parent.is_a?(Sketchup::Model)
          #~ if(ci.get_attribute('SPOBJ',"numParents",nil)!=nil)
            #~ dict=ci.attribute_dictionaries['SPOBJ']
            #~ dict.each_pair { | key, value |
              #~ if(key.include?("jointParent") && value==jname)
                #~ kids.push(ci)
              #~ end
            #~ }
          #~ end
        }
      }
      kids
    end

    def findObjectsJoints(ent)
      joints = []
      jnames = JointConnectionTool.getParentJointNames(ent)
      jnames.each { |jname|
        jnt = @allJoints[jname]
        if jnt
          joints << jnt # lookup joint
        else
           puts "Missing joint #{jname}"
           JointConnectionTool.disconnectJointNamed(ent, jname)
        end
      }
      return joints
      #~ if(ent.get_attribute('SPOBJ',"numParents",nil)!=nil)
        #~ dict=ent.attribute_dictionaries['SPOBJ']
        #~ dict.each_pair { | key, value |
          #~ if(key.include?("jointParent") && value!=nil)
            #~ jnt=@allJoints[value]
            #~ if(jnt==nil)
               #~ puts "Missing joint "+value.to_s
               #~ disconnectJointNamed(ent,key)
            #~ else
              #~ joints.push(jnt)#lookup joint
            #~ end
          #~ end
        #~ }
      #~ end
      #~ return joints
    end

    def disconnectJoint(joint, child)
      # Verify child not already connected to joint.
      # Verify joint isnt inside child.

      # Check for swap of joint/child
      if child.get_attribute('SPJOINT', 'name', nil)
        temp = joint
        joint = child
        child = temp
      end

      Sketchup.active_model.start_operation "Disconnect from joint #{joint.name}"

      jname = joint.get_attribute('SPJOINT', 'name', nil)
      cname = child.get_attribute('SPJOINT', 'name', nil)
      puts "Disconnect #{cname} from #{jname}"
      JointConnectionTool.disconnectJointNamed(joint, cname)
      JointConnectionTool.disconnectJointNamed(child, jname)

      if jname!=nil && cname!=nil
        #~ ga=joint.get_attribute('SPJOINT',"gearjoint",nil)
        #~ gb=child.get_attribute('SPJOINT',"gearjoint",nil)
        #~ if(ga!=nil && ga==child.get_attribute('SPJOINT','name',nil))
          #~ joint.delete_attribute('SPJOINT','name')
          #~ joint.delete_attribute('SPJOINT',"geartype")
          #~ joint.delete_attribute('SPJOINT',"ratio")
          #~ puts("Disconnected Gear")

        #~ end
        #~ if(gb!=nil && gb==child.get_attribute('SPJOINT','name',nil))
          #~ child.delete_attribute('SPJOINT','name')
          #~ child.delete_attribute('SPJOINT',"geartype")
          #~ child.delete_attribute('SPJOINT',"ratio")
          #~ puts("Disconnected gear")

        #~ end
        puts "Disconnected Gear #{child.name} from #{joint.name}."
      end

      Sketchup.active_model.commit_operation
    end

    # NOTE: Called after onLButtonDown and onLButtonUp.
    def onLButtonDoubleClick(flags, x, y, view)
      Sketchup.active_model.selection.add(@relatedObjects) unless @ctrlDown
      if (@ctrlDown || @shiftDown) && @relatedObjects.size > 0
        @ctrlDown = false # debounce key
        @shiftDown = false # debounce key
        if @selectedIsJoint
          keypress = UI.messagebox("Are you sure you want to disconnect these #{@relatedObjects.size} objects?", MB_YESNO, 'Error')
          if keypress == 6
            puts "Joint disconnect #{@relatedObjects.size} from #{@selectedObject.name}"
            @relatedObjects.each { |e| disconnectJoint(@selectedObject, e) }
          end
        else
          keypress = UI.messagebox("Are you sure you want to disconnect from these #{@relatedObjects.size} joints?", MB_YESNO, 'Error')
          if keypress == 6
            puts "Disconnect #{@selectedObject.name} from #{@relatedObjects.size}."
            @relatedObjects.each { |e| disconnectJoint(@selectedObject,e) }
          end
        end
      end
      refresh_viewport
    end

    def onLButtonDown(flags, x, y, view)
      @dragCount = 0
      @lButtonDown = true
      @inputPoint = Sketchup::InputPoint.new
      @inputPoint.pick view, x, y

      ph = view.pick_helper
      num = ph.do_pick x,y
      ent = ph.best_picked

      unless ent.is_a?(Sketchup::Group) or ent.is_a?(Sketchup::ComponentInstance)
        doSelectObject(nil)
        return
      end

      @selectedParent = nil
      joint = pickEmbeddedJoint(x, y, view)
      if joint != nil && joint.get_attribute('SPJOINT', 'name', nil)
        @selectedParent = ent
        ent = joint
      end
      doSelectObject(ent)
      refresh_viewport
    end

    def onLButtonUp(flags, x, y, view)
      @lButtonDown = false
      return unless @dragging
      @dragging = false
      return unless @dropGroup
      return unless @selectedGroup
      if @ctrlDown
        disconnectJoint(@selectedObject, @dropGroup)
      else
        JointConnectionTool.connectJoint(@selectedObject, @dropGroup)
      end
      doSelectObject(nil)
      refresh_viewport
    end

    def onMouseMove(flags, x, y, view)
      if false # if @lButtonDown && @selectedObject != nil
        @dragCount += 1
        @dragging=true if @dragCount > 10
      else
        @dragging = false
      end

      ph = view.pick_helper
      ph.do_pick x,y
      ent = ph.best_picked

      if ent && (ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance))
        @hoverGroup = ent
      else
        @hoverGroup = nil
      end

      joint = pickEmbeddedJoint(x, y, view)
      if joint != nil && joint.get_attribute('SPJOINT', 'name', nil)
        if @hoverJoint != joint
          @hoverJoint = joint
          @hoverJointGroup = @hoverGroup
        end
      else
        @hoverJoint = nil
        @hoverJointGroup = nil
      end

      if @dragging && @selectedObject != nil
        ip = Sketchup::InputPoint.new
        ip.pick(view, x, y)
        @dropPoint = ip
        dc = @selectedIsJoint ? @hoverGroup : @hoverJoint
        @dropGroup = validDropTarget(dc) ? dc : nil
        Sketchup.active_model.selection.clear
        Sketchup.active_model.selection.add(@selectedObject)
        Sketchup.active_model.selection.add(@dropGroup) if @dropGroup
        view.invalidate
      else
        @dropPoint = nil
      end
    end

    def validDropTarget(ent)
      return (@relatedObjects.index(ent) != nil) if @ctrlDown
      return false if @relatedObjects.index(ent)
      if @selectedIsJoint
        # if ent is object
        # and ent isnt a joint
        # and not already connected
        # and not joint's group
      end
      true
    end

    # Called when I press middle mouse button (goes into orbit)
    def suspend(view)
      #puts "suspend called"
    end

  class << self

    def convertConnections(group)
      ja = group.get_attribute('SPOBJ', 'parentJoints', [])
      dict = group.attribute_dictionaries['SPOBJ']
      keys = []
      dict.each_pair { | key, value |
        if key.include?('jointParent') && value != nil
          ja << value
          keys << key
          #group.delete_attribute('SPOBJ', key)
        end
      }
      group.delete_attribute('SPOBJ', 'numParents')
      keys.each { |k| group.delete_attribute('SPOBJ', k) }
      group.set_attribute('SPOBJ', 'parentJoints', ja) if ja.size > 0
      puts "Converted #{ja.length} connections for #{group}."
    end

    def getParentJointNames(group)
      if group.get_attribute('SPOBJ', 'numParents', nil) != nil
        convertConnections(group)
      end
      group.get_attribute('SPOBJ', 'parentJoints', [])
    end

    def disconnectJointNamed(ent, name)
      ja = ent.get_attribute('SPOBJ', 'parentJoints', [])
      c = ja.length
      ja.delete_if { |jn| jn == name }
      if c != ja.size
        puts "Disconnected #{name} (#{c}/#{ja.length}}"
        ent.set_attribute('SPOBJ', 'parentJoints', ja)
      end
    end

    def disconnectAllJoints(group)
      group.delete_attribute('SPOBJ', 'parentJoints')
      puts "Disconnected all joints from #{group}"
    end

    def old_disconnectJointNamed(ent,name)
      return unless ent.get_attribute('SPOBJ', name, nil)
      ent.delete_attribute('SPOBJ', name) # Disconnect joint
      c = ent.get_attribute('SPOBJ', 'numParents', 0)
      ent.set_attribute('SPOBJ', 'numParents', c-1) # Decrement parent count
      puts "Disconnected #{name}"
    end

    def attach(parent, child)
      childID = MSketchyPhysics3.get_unique_id(child)
      parentID = MSketchyPhysics3.get_unique_id(parent)
      puts "Attach #{child.name}(#{childID}) to #{parent.name}(#{parentID})"
      child.set_attribute('SPOBJ', 'parentname', parent.name)
      child.set_attribute('SPOBJ', 'parentid', parentID)
      child.set_attribute('SPOBJ', 'jointtype', 'hinge')
    end

    def groupIsJoint(group)
      group.get_attribute('SPJOINT', 'name', nil) != nil
    end

    #~ #2 joints are geared
    #Rule(?) geared joints means joint parent only.

    #~ #if joint is in body that is body
    #~ #else each joint childeren

    #each body could have a parent or a child joint or both

    #2 bodies are geared.
    #find joint pins.
    #if body has single child joint that is the joint
    #elsif body has single parent joint that is the joint
    #if body has multiple child joints?
    #if body has multiple parent joints?
    def connectJoint(joint, child)
      # Check connect two objects.
      if groupIsJoint(joint) && groupIsJoint(child)
        # TODO: if either is gear and one is joint
        # store joint name in gear
        puts "Connect joint to joint. Make gear?"
        puts joint.parent
        puts child.parent

        atype = joint.get_attribute('SPJOINT', 'type', nil)
        btype = child.get_attribute('SPJOINT', 'type', nil)
        if %w(hinge servo motor).include?(atype)
          if %w(hinge servo motor).include?(btype)
            gtype = 'gear'
          elsif btype == 'slider' || btype == 'piston'
            gtype = 'wormgear'
          end
        elsif atype == 'slider' || atype == 'piston'
          if btype == 'slider' || btype == 'pulley'
            gtype = 'pulley'
          elsif %w(hinge servo motor).include?(atype)
            gtype = 'wormgear'
            puts 'Need swap!!'
          end
        end

        if UI.messagebox("Create gear #{gtype} between #{atype} and #{btype}?", MB_OKCANCEL, 'Create Gear') ==1
          joint.set_attribute('SPJOINT', 'gearjoint', child.get_attribute('SPJOINT', 'name', nil))
          joint.set_attribute('SPJOINT', 'geartype', gtype)
          joint.set_attribute('SPJOINT', 'ratio', 1.0)
          joint.set_attribute('SPJOINT', 'GearConnectedCollide', false)
        end
      end

      # Check connect two objects.
      if(!groupIsJoint(joint) && !groupIsJoint(child))
        puts "Connect Object #{joint.name} to #{child.name}"
      end

      # Check for swap of joint/child
      if child.get_attribute('SPJOINT', 'name', nil) != nil
        temp = joint
        joint = child
        child = temp
      end

      jointParentName = joint.get_attribute('SPJOINT', 'name', nil)
      jnames = JointConnectionTool.getParentJointNames(child)

      # Verify child not already connected to joint.
      if jnames.index(jointParentName)
        puts "#{child.name} already connected to #{jointParentName.to_s}"
        return
      end

      # Verify joint isn't inside child
      MSketchyPhysics3.get_entities(child).each { |ent|
        if ent == joint
          puts 'Cant connect to internal joints!'
          return
        end
      }

      puts "Connect #{joint.name} to #{child.name}."
      Sketchup.active_model.start_operation "Connect to joint #{joint.name}"
      jnames << jointParentName
      child.set_attribute('SPOBJ', 'parentJoints', jnames)
      Sketchup.active_model.commit_operation
    end

  end # proxy class
end # class JointConnectionTool
end # module MSketchyPhysics3
