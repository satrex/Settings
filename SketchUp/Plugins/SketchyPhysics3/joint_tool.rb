# Copyright 2004-2005, @Last Software, Inc.

# This software is provided as an example of using the Ruby interface
# to SketchUp.

# Permission to use, copy, modify, and distribute this software for
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Adapted from the sketchup example   Rotated Rectangle Tool 1.0
# Additions copyright Chris Phillips

require 'sketchup.rb'

module MSketchyPhysics3

#min,max 0=hinge/motor
#hinge
#min/max rotation
#accel/damp
#controller. for servo(desired offset)

#slider
#min/max offset. Option for component limits.
#accel/damp. for spring.
#controller. for piston.(desired offset)

#motor
#min/max acceleration
#accel/damp
#desired accel.

#~ DefaultJointSettingsTable=[
    #~ ["hinge",0.0,0.0],
    #~ ["slider",0.0,0.0],
    #~ ["servo",-90.0,90.0,0.0,0.0],
    #~ ["piston",0.0,0.0],


#~ ]
#~ def convertJoint(grp,newType)

#~ end

  class << self

    def convertControlledJoint(joint)
      controller = joint.get_attribute('SPJOINT', 'controller', nil)
      return unless controller
      # puts 'Converting joint to 3.0 controller'
      joint.set_attribute('SPJOINT', 'controller', nil)
      if controller.index('oscillator')
        vals = controller.split(',')
        rate = vals[1].to_f
        joint.set_attribute('SPJOINT', 'Controller', "oscillator(#{rate})")
      else
        case controller.strip
          when ''
            joint.set_attribute('SPJOINT', 'Controller', '')
          when 'joyLX', 'joyLY', 'joyRX', 'joyRY'
            joint.set_attribute('SPJOINT', 'Controller', controller)
          else
            joint.set_attribute('SPJOINT', 'Controller', "slider('#{controller}')")
        end
      end
      # controller = joint.get_attribute('SPJOINT', 'controller', '')
    end

    def oldconvertControlledJoint(grp)
      c = grp.get_attribute('SPJOINT', 'controller', nil)
      return unless c
      grp.set_attribute('SPJOINT', 'controller', nil)
      case grp.get_attribute('SPJOINT', 'type', nil)
        when 'servo'
        when 'hinge'
          grp.set_attribute('SPJOINT', 'DesiredRotation', 'slider("'+c+'")')
        when 'slider'
        when 'piston'
          grp.set_attribute('SPJOINT', 'DesiredPosition', 'slider("'+c+'")')
        when 'motor'
          grp.set_attribute('SPJOINT', 'DesiredAccel', 'slider("'+c+'")')
      end
    end

    # Needed to properly handle undo.
    def preloadJoint(type)
      dir = File.dirname(__FILE__)
      path = File.join(dir, "joints/#{type}.skp")
      cd = Sketchup.active_model.definitions.load(path)
    end

    def makePhysicsJoint(type, pt1, pt2, parent_ents)
      model = Sketchup.active_model
      depth = pt1.distance(pt2)
      if getKeyState(VK_LOPTION)
        case type
          when 'hinge'
            type = 'servo'
          when 'slider'
            type = 'piston'
        end
      end
      dir = File.dirname(__FILE__)
      path = File.join(dir, "joints/#{type}.skp")
      cd = ( File.exists?(path) ? model.definitions.load(path) : nil)
      if RUBY_VERSION.to_i > 6
        model.start_operation("Create #{type}", true)
      else
        model.start_operation("Create #{type}")
      end
      group = parent_ents.add_group

      # model.commit_operation
      # model.commit_operation
      # return
      # len = (pt2-pt1).length.to_f #pt1.distance(pt2)
      # group.entities.add_line([0,0,0], [0,0,len])
      # txt = group.entities.add_text(type, [0,0,0])
      # txt.layer = model.layers.add('Physics labels')

      group.entities.add_instance(cd, Geom::Transformation.new)
      v = pt2 - pt1
      a = v.axes
      t = Geom::Transformation.new(a[0], a[1], a[2], pt1)
      group.transform!(t)

      group.set_attribute('SPJOINT', 'type', type)

      name = type+group.entityID.to_s
      group.set_attribute('SPJOINT', 'name', name)

      case type
        when 'fixed'
          group.set_attribute('SPJOINT', 'breakingForce', 0)
        when 'ball'
          group.set_attribute('SPJOINT', 'min', 180)
          group.set_attribute('SPJOINT', 'max', 10)
        when 'hinge'
          group.set_attribute('SPJOINT', 'min', 0.0)
          group.set_attribute('SPJOINT', 'max', 0.0)
          group.set_attribute('SPJOINT', 'accel', 0.0)
          group.set_attribute('SPJOINT', 'damp', 0.0)
          group.set_attribute('SPJOINT', 'Controller', '')
          # group.set_attribute('SPJOINT', 'DesiredRotation', '')
        when 'slider'
          len = (pt2-pt1).length.to_f # pt1.distance(pt2)
          group.entities.add_line([0,0,0], [0,0,len])
          group.set_attribute('SPJOINT', 'min', 0.0)
          group.set_attribute('SPJOINT', 'max', len)
          group.set_attribute('SPJOINT', 'accel', 0.0)
          group.set_attribute('SPJOINT', 'damp', 0.0)
          group.set_attribute('SPJOINT', 'Controller', '')
          # group.set_attribute('SPJOINT', 'DesiredPosition', '')
        when 'spring'
          group.set_attribute('SPJOINT', 'accel', 0.0)
          group.set_attribute('SPJOINT', 'damp', 0.0)
        when 'corkscrew'
          group.set_attribute('SPJOINT','min', 0.0)
          group.set_attribute('SPJOINT','max', 0.0)

#Controller
# joint,controlledAttribute,

#joinDefinitions[type]
#   defaultProperties([min,max,accel,damp,springStiff,springDamp,desiredOffset,friction])
#   visibleProperties([[name,index,type][][]])
#       PCV min,max;
#       PCV accel,damp;
#       PCV springStiff,springDamp;
#       PCV desiredOffset;
#       PCV friction;

        when 'gear'
          group.set_attribute('SPJOINT', 'ratio', 1.0)
        when 'pulley'
          group.set_attribute('SPJOINT', 'ratio', 1.0)
        when 'wormgear'
          group.set_attribute('SPJOINT', 'ratio', 1.0)
        when 'motor'
          # group.set_attribute('SPJOINT', 'min', 0) #ignored
          # group.set_attribute('SPJOINT', 'max', 0) #ignored
          group.set_attribute('SPJOINT', 'minAccel', 1.0)
          group.set_attribute('SPJOINT', 'maxAccel', 1.0)
          group.set_attribute('SPJOINT', 'damp', 0.5)
          group.set_attribute('SPJOINT', 'Controller', "slider('#{name}')")
          # group.set_attribute('SPJOINT', 'DesiredAccel', '')
          # group.set_attribute('SPJOINT', 'throttleController', %w(none LAxisUD LAxisLR RAxisUD RAxisLR))
        when 'piston'
          # Draw line to represent length.
          len = (pt2-pt1).length.to_f #pt1.distance(pt2)
          group.entities.add_line([0,0,0], [0,0,len])
          # group.set_attribute('SPJOINT', 'DesiredPosition', '')
          group.set_attribute('SPJOINT', 'Controller', "slider('#{name}')")
          group.set_attribute('SPJOINT', 'min', 0.0)
          group.set_attribute('SPJOINT', 'max', len)
          group.set_attribute('SPJOINT', 'accel', 40.0)
          group.set_attribute('SPJOINT', 'damp', 10.0)
        when 'servo'
          # group.set_attribute('SPJOINT', 'DesiredRotation', '')
          group.set_attribute('SPJOINT', 'Controller', "slider('#{name}')")
          group.set_attribute('SPJOINT', 'min', -90.0)
          group.set_attribute('SPJOINT', 'max', 90.0)
          group.set_attribute('SPJOINT', 'accel', 40.0)
          group.set_attribute('SPJOINT', 'damp', 10.0)
        when 'gyro'
          # group.set_attribute('SPJOINT', 'DesiredRotation', '')
          group.set_attribute('SPJOINT', 'accel', 0.0)
          group.set_attribute('SPJOINT', 'damp', 0.0)
          group.set_attribute('SPJOINT', 'Controller', '[0,0,1]')
        when 'oscillator'
          group.set_attribute('SPJOINT', 'Controller', name)
          group.set_attribute('SPJOINT', 'min', -10.0)
          group.set_attribute('SPJOINT', 'max', 10.0)
          group.set_attribute('SPJOINT', 'accel', 0.0)
          group.set_attribute('SPJOINT', 'damp', 0.0)
          group.set_attribute('SPJOINT', 'rate', 100.0)
        when 'magnet'
          group.set_attribute('SPJOINT', 'strength', 1000.0)
          # group.set_attribute('SPJOINT', 'range', 100.0)
          # group.set_attribute('SPJOINT', 'falloff', 1.0)
          group.set_attribute('SPJOINT', 'duration', 9999)
          group.set_attribute('SPJOINT', 'delay', 0)
          group.set_attribute('SPJOINT', 'rate', 0)
      end

      group.set_attribute('SPJOINT', 'ConnectedCollide', false)

      group.name=name
      group.set_attribute('SPOBJ', 'static', true)
      group.set_attribute('SPOBJ', 'ignore', true)

      model.layers.add('Physics joints')
      group.layer = 'Physics joints'

      model.commit_operation
      model.selection.clear
      model.selection.add(group)

      return group
    rescue Exception => e
      model.abort_operation
      UI.messagebox(e)
      return
    end

  end # proxy class

#~ #desiredRotation,desiredPosition,desiredAccel
#~ OmniJointStruct = Struct.new(:name,:type,
                        #~ :min, :max, :accel,
                        #~ :damp,:desiredOffset)
#~ #,:update,:jointPtr
#~ def createOmniJoint(type)
#~ end

  class CreateJointTool

    def initialize(joint_type)
      @jointType = joint_type
      @ip = Sketchup::InputPoint.new
      @ip1 = Sketchup::InputPoint.new
      reset
    end

    def reset
      @pts = []
      @last_pos = [0,0]
      @state = 0
      @ip1.clear
      @drawn = false
      Sketchup.set_status_text '', SB_VCB_LABEL
      Sketchup.set_status_text '', SB_VCB_VALUE
      Sketchup.set_status_text 'Click for start point'
      @shift_down_time = Time.now
      # Sketchup.active_model.abort_operation
    end

    def activate
      reset
    end

    def deactivate(view)
      view.invalidate if @drawn
    end

    def set_current_point(x, y, view)
      return false unless @ip.pick(view, x, y, @ip1)
      need_draw = true
      # Set the tooltip that will be displayed
      view.tooltip = @ip.tooltip
      # Compute points
      case @state
        when 0
          @pts[0] = @ip.position
          @pts[4] = @pts[0]
          need_draw = @ip.display? || @drawn
        when 1
          @pts[1] = @ip.position
          @width = @pts[0].distance @pts[1]
          Sketchup.set_status_text @width.to_s, SB_VCB_VALUE
        when 2
          pt1 = @ip.position
          pt2 = pt1.project_to_line @pts
          vec = pt1 - pt2
          @height = vec.length
          if @height > 0
            # Test for a square
            square_point = pt2.offset(vec, @width)
            if view.pick_helper.test_point(square_point, x, y)
              @height = @width
              @pts[2] = @pts[1].offset(vec, @height)
              @pts[3] = @pts[0].offset(vec, @height)
              view.tooltip = 'Square'
            else
              @pts[2] = @pts[1].offset(vec)
              @pts[3] = @pts[0].offset(vec)
            end
          else
            @pts[2] = @pts[1]
            @pts[3] = @pts[0]
          end
          Sketchup.set_status_text @height.to_s, SB_VCB_VALUE
      end
      view.invalidate if need_draw
    end

    def onMouseMove(flags, x, y, view)
      set_current_point(x, y, view)
    end

    def create_rectangle
      # Check for zero height
      if( @pts[0] != @pts[3] )
        puts "Making #{@pts}"
        Sketchup.active_model.active_entities.add_face @pts
      end
      # reset
    end

    def increment_state
      @state += 1
      model = Sketchup.active_model
      case @state
      when 1
        @ip1.copy! @ip
        Sketchup.set_status_text 'Click for second point'
        Sketchup.set_status_text 'Width', SB_VCB_LABEL
        Sketchup.set_status_text '', SB_VCB_VALUE
      when 2
        # preloadJoint(@jointType) # Make sure joint is loaded, undo is messed up otherwise.
        grp = MSketchyPhysics3.makePhysicsJoint(@jointType, @pts[0], @pts[1], model.active_entities)
        if @potentialParent and grp
          keypress = UI.messagebox("Connect #{@potentialParent.name} to #{grp.name}? ", MB_YESNO, 'Connect Joint?')
          JointConnectionTool.connectJoint(grp, @potentialParent) if (keypress == 6)
        end
        # model.selection.clear()
        # model.selection.add(grp) #11-23-07
        # $spObjectInspector.selectObject(grp)
        reset
        # model.select_tool(nil)
        @ip1.clear
        Sketchup.set_status_text 'Click for third point'
        Sketchup.set_status_text 'Height', SB_VCB_LABEL
        Sketchup.set_status_text '', SB_VCB_VALUE
      when 3
        create_rectangle
        @ip1.clear
        Sketchup.set_status_text 'Click for third point'
        Sketchup.set_status_text 'Height', SB_VCB_LABEL
        Sketchup.set_status_text '', SB_VCB_VALUE
        @state=2
        # model.commit_operation
        # reset
        # model.select_tool(nil)
      end
    end

    def onLButtonDown(flags, x, y, view)
      # ph = view.pick_helper
      # num = ph.do_pick x,y
      # if ph.best_picked.is_a?(Sketchup::Group)
      #   Sketchup.active_model.selection.clear
      #   Sketchup.active_model.selection.add ph.best_picked
      # end
      # puts ph.best_picked.to_s
      if  @state == 0
        ph = view.pick_helper
        num = ph.do_pick x,y
        ent = ph.best_picked
        if getKeyState(VK_LOPTION) && ( ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance) )
          @potentialParent = ent
        else
          @potentialParent = nil
        end
      end
      set_current_point(x, y, view)
      if (x - @last_pos[0]).abs > 10 || (y - @last_pos[1]).abs > 10
        increment_state
        @last_pos = [x,y]
      end
      view.lock_inference
    end

    def onCancel(flag, view)
      view.invalidate if @drawn
      reset
    end

    # This is called when the user types a value into the VCB
    def onUserText(text, view)
      # The user may type in something that we can't parse as a length
      # so we set up some exception handling to trap that
      begin
        value = text.to_l
      rescue
        # Error parsing the text
        UI.beep
        value = nil
        Sketchup.set_status_text '', SB_VCB_VALUE
      end
      return unless value
      case @state
      when 1
        # update the width
        vec = @pts[1] - @pts[0]
        if vec.length > 0.0
          vec.length = value
          @pts[1] = @pts[0].offset(vec)
          view.invalidate
          increment_state
        end
      when 2
        # update the height
        vec = @pts[3] - @pts[0]
        if vec.length > 0.0
          vec.length = value
          @pts[2] = @pts[1].offset(vec)
          @pts[3] = @pts[0].offset(vec)
          increment_state
        end
      end
    end

    def getExtents
      bb = Geom::BoundingBox.new
      case @state
      when 0
        # We are getting the first point
        bb.add(@ip.position) if @ip.valid? && @ip.display?
      when 1
        bb.add @pts[0]
        bb.add @pts[1] if @pts[1]
      when 2
        bb.add @pts
      end
      bb
    end

    def draw(view)
      @drawn = false
      # Show the current input point
      if @ip.valid? && @ip.display?
        @ip.draw(view)
        @drawn = true
      end
      # Show the rectangle
      if @state == 1
        # Just draw a line from the start to the end point
        view.set_color_from_line(@ip1, @ip)
        inference_locked = view.inference_locked?
        view.line_width = 3
        view.line_width = 5 if inference_locked
        view.draw(GL_LINE_STRIP, @pts[0], @pts[1])
        view.line_width = 1 if inference_locked
        @drawn = true
      elsif @state > 1
        # draw the curve
        view.drawing_color = 'black'
        view.draw(GL_LINE_STRIP, @pts)
        @drawn = true
      end
    end

    def onKeyDown(key, rpt, flags, view)
      if key == CONSTRAIN_MODIFIER_KEY && rpt == 1
        @shift_down_time = Time.now
        # if we already have an inference lock, then unlock it
        if view.inference_locked?
          view.lock_inference
        elsif @state == 0
          view.lock_inference @ip
        elsif @state == 1
          view.lock_inference @ip, @ip1
        end
      end
    end

    def onKeyUp(key, rpt, flags, view)
      if( key == CONSTRAIN_MODIFIER_KEY &&
          view.inference_locked? &&
          (Time.now - @shift_down_time) > 0.5 )
        view.lock_inference
      end
    end

  end # class CreateJointTool

# ==============================================================================

  def setJointSettings
    selected = Sketchup.active_model.selection.first
    #unless selected.get_attribute('SPJOINT', 'min', nil)
    #  selected.set_attribute('SPJOINT', 'min', 0.0)
    #  selected.set_attribute('SPJOINT', 'max', 0.0)
    #  selected.set_attribute('SPJOINT', 'accel', 0.0)
    #  selected.set_attribute('SPJOINT', 'damp', 0.0)
    #end
    prompts = []
    values = []
    v = selected.get_attribute('SPJOINT', 'min', nil)
    if v
      prompts.push('min')
      values << v
    end
    v = selected.get_attribute('SPJOINT', 'max', nil)
    if v
      prompts.push('max')
      values << v
    end
    v = selected.get_attribute('SPJOINT', 'accel', nil)
    if v
      prompts.push('accel')
      values << v
    end
    v = selected.get_attribute('SPJOINT', 'damp', nil)
    if v
      prompts.push('damp')
      values << v
    end
    v = selected.get_attribute('SPJOINT', 'rate', nil)
    if v
      prompts.push('rate')
      values << v
    end
    v = selected.get_attribute('SPJOINT', 'range', nil)
    if v
      prompts.push('range')
      values << v
    end
    results = inputbox(prompts, values, 'Joint Settings')

    if results && results != values
      0.upto(prompts.length-1) do |xx|
        selected.set_attribute('SPJOINT', prompts[xx], results[xx])
      end
    end

  end

# foreach duplicated joint
# figureout which is the copy and which is the original
# Find all objects that parent to each of the joints
# Leave unique relationships alone
# for all common joint connects
# if object is a copy of

  class CopyJointWatcher
    def onElementAdded(es, e)
      if((e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)) &&
          e.get_attribute('SPJOINT', 'name', nil) != nil)
        # Sketchup.active_model.start_operation 'Copy Joint'
        # e.set_attribute('SPJOINT', 'name', e.get_attribute('SPJOINT', 'name', nil)+e.entityID.to_s)
        # Sketchup.active_model.commit_operation
        # puts e.get_attribute('SPJOINT', 'name', nil)
        # puts "Creating new joint:" + e.get_attribute('SPJOINT', 'name', nil).to_s
        # @createdFace = e
        # Sketchup.active_model.selection.add(e)
      end
    end
  end

  def watchJoints
    obs = CopyJointWatcher.new
    Sketchup.active_model.active_entities.add_observer(obs)
  end

end # module MSketchyPhysics3
