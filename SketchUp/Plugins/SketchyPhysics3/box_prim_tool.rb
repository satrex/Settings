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
# Original Name       :   Rotated Rectangle Tool 1.0
#-----------------------------------------------------------------------------
#Adapted to a 3d box tool by Chris Phillips

require 'sketchup.rb'

module MSketchyPhysics3
class BoxPrimTool

def initialize(jointType)
  @ip = Sketchup::InputPoint.new
  @ip1 = Sketchup::InputPoint.new
  @defaultJointType=jointType
  @bb = Geom::BoundingBox.new
  reset
end

def reset
  if(@centerLine!=nil)
    Sketchup.active_model.abort_operation # get rid of cline
    @centerLine=nil
  end

  @depth=nil
  @extrudePoint=nil
  @center=nil
  @normal=nil

  @pts = []
  @state = 0
  @ip1.clear
  @drawn = false
  Sketchup::set_status_text "", SB_VCB_LABEL
  Sketchup::set_status_text "", SB_VCB_VALUE
  Sketchup::set_status_text "Click for start point"
  @shift_down_time = Time.now
end

def activate
  self.reset
end

def deactivate(view)
  @centerLine.erase! if @centerLine && @centerLine.valid?
  view.invalidate if @drawn
end

def set_current_point(x, y, view)
  if( !@ip.pick(view, x, y, @ip1) )
    return false
  end
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
    Sketchup::set_status_text @width.to_s, SB_VCB_VALUE
  when 2
    pt1 = @ip.position
    pt2 = pt1.project_to_line @pts
    vec = pt1 - pt2
    @height = vec.length

    if( @height > 0 )
      # test for a square
      square_point = pt2.offset(vec, @width)
      if( view.pick_helper.test_point(square_point, x, y) )
        @height = @width
        @pts[2] = @pts[1].offset(vec, @height)
        @pts[3] = @pts[0].offset(vec, @height)
        view.tooltip = "Square"
      else
        @pts[2] = @pts[1].offset(vec)
        @pts[3] = @pts[0].offset(vec)
      end
    else
      @pts[2] = @pts[1]
      @pts[3] = @pts[0]
    end

    v1=(@pts[1]-@pts[2])
    v2=(@pts[3]-@pts[2])
    @normal= v1.cross(v2)

    vc=(@pts[2]-@pts[0])
    vc.length=vc.length/2;
    @center=@pts[0]+vc

    Sketchup::set_status_text @height.to_s, SB_VCB_VALUE
  when 3
    vp=@ip.position
    if(!@ip.display?)# if not on a valid point then infer position in screen space.
      la=[@center,@normal]# line from center of shape "up" along its normal.
      lb=[view.camera.eye,@ip.position]#line from eye to 3dpoint under cursor.

      #view.draw(GL_LINE_STRIP, Geom.closest_points(la,lb))
      vp=Geom.closest_points(la,lb)[0]  #find the point of closest approach for the two lines.

      #view.draw_points(vp, 2, 1, "red")
    end

    #limit extrude to the normal direction.
    @extrudePoint=vp.project_to_line([@center,@normal])
    @depth=@extrudePoint.distance(@center)
    #puts @extrudePoint-@center
    Sketchup::set_status_text @depth.to_s, SB_VCB_VALUE
  end
  view.invalidate if need_draw
end

def onMouseMove(flags, x, y, view)
  self.set_current_point(x, y, view)
end

def create_rectangle
  # check for zero height
  if( @pts[0] != @pts[3] )
    Sketchup.active_model.active_entities.add_face @pts
  end
  self.reset
end
def makePhysicsCube(parentEnts,width,height,depth)

  group=parentEnts.add_group
  pts = [[0,0,0], [width,0,0], [width,height,0], [0,height,0], [0,0,0]]
  pts = [[-(width/2),-(height/2),-(depth/2)],
       [width/2,-(height/2),-(depth/2)],
       [width/2,height/2,-(depth/2)],
       [-(width/2),height/2,-(depth/2)],
       [-(width/2),-(height/2),-(depth/2)]]
  base = group.entities.add_face pts
  depth = -depth if base.normal.dot(Z_AXIS) < 0.0
  base.pushpull depth
  MSketchyPhysics3::setPhysicsAttribute(group,"shape","box")
  group.name="box"
  return(group)
end

def increment_state
  @state += 1
  case @state
  when 1
    @ip1.copy! @ip
    Sketchup::set_status_text "Click for second point"
    Sketchup::set_status_text "Width", SB_VCB_LABEL
    Sketchup::set_status_text "", SB_VCB_VALUE
  when 2
    @ip1.clear
    Sketchup::set_status_text "Click for third point"
    Sketchup::set_status_text "Height", SB_VCB_LABEL
    Sketchup::set_status_text "", SB_VCB_VALUE
  when 3
    if Sketchup.version.to_i > 6
      Sketchup.active_model.start_operation('Solid Tool', true)
    else
      Sketchup.active_model.start_operation('Solid Tool')
    end
    @centerLine=Sketchup.active_model.active_entities.add_cline(@center, @normal)
    #self.create_rectangle
  when 4
    if(@depth==0)
      @state -= 1
      return
    end
    Sketchup.active_model.abort_operation #get rid of cline
    @centerLine.erase! if @centerLine.valid?
    @centerLine = nil
    #uneeded?? preloadJoint(@defaultJointType) if(@potentialParent!=nil&& @defaultJointType!=nil)
    if Sketchup.version.to_i > 6
      Sketchup.active_model.start_operation('Create Box', true)
    else
      Sketchup.active_model.start_operation('Create Box')
    end
    parent=nil
    if(@potentialParent!=nil&& @defaultJointType!=nil)
      parent=Sketchup.active_model.active_entities.add_group()
      grp=makePhysicsCube(parent.entities,@width,@height,@depth)
    else
      grp=makePhysicsCube(Sketchup.active_model.active_entities,@width,@height,@depth)
    end
    v1=(@pts[0]-@pts[1])
    v2=(@pts[0]-@pts[3])
    v3=(@extrudePoint-@center)

    if(v1.cross(v2).dot(v3)<0)
      v1.reverse!
    end

    #xform=Geom::Transformation.new([@width/2,@height/2,@depth/2])*
    xform=Geom::Transformation.new(v1,v2,v3,@center)*Geom::Transformation.new([0,0,@depth/2])

    grp.transform!(xform)

    if(Sketchup.active_model.materials.current!=nil)
      #grp.material=Sketchup.active_model.materials.current
    end
    Sketchup.active_model.commit_operation

    if(@potentialParent!=nil&& @defaultJointType!=nil)
      jnt=MSketchyPhysics3::makePhysicsJoint(@defaultJointType,@pts[0],@pts[0]+v3,parent.entities)
      puts "Attach to: #{@potentialParent}"
      JointConnectionTool.connectJoint(jnt,@potentialParent)
      Sketchup.active_model.selection.clear()
      Sketchup.active_model.selection.add(parent)
    else
      Sketchup.active_model.selection.clear()
      Sketchup.active_model.selection.add(grp)
    end
    self.reset
  end
end

def onLButtonDown(flags, x, y, view)
  self.set_current_point(x, y, view)
  self.increment_state

  if(@state==1)
    ph=view.pick_helper
    num=ph.do_pick x,y
    ent=ph.best_picked
    puts "Potential Parent: #{ent}" if ent

    if(ent.class==Sketchup::Group || ent.class==Sketchup::ComponentInstance)
      @potentialParent=ent
    else
      @potentialParent=nil
    end
  end

  view.lock_inference
end

def onCancel(flag, view)
  view.invalidate if @drawn
  self.reset
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
    Sketchup::set_status_text "", SB_VCB_VALUE
  end
  return if !value

  case @state
  when 1
    # update the width
    vec = @pts[1] - @pts[0]
    if( vec.length > 0.0 )
      vec.length = value
      @pts[1] = @pts[0].offset(vec)
      view.invalidate
      self.increment_state
    end
  when 2
    # update the height
    vec = @pts[3] - @pts[0]
    if( vec.length > 0.0 )
      vec.length = value
      @pts[2] = @pts[1].offset(vec)
      @pts[3] = @pts[0].offset(vec)
      self.increment_state
    end
  end
end

def getExtents
  case @state
  when 0
    # We are getting the first point
    if( @ip.valid? && @ip.display? )
      @bb.add @ip.position
    end
  when 1
    @bb.add @pts[0]
    @bb.add @pts[1] if @pts[1]!=nil
  when 2
    @bb.add @pts[0]
    @bb.add @pts[2] if @pts[2]!=nil
    @bb.add @pts[3] if @pts[3]!=nil
  end
  @bb
end

def draw(view)
  @drawn = false
  @bb.clear
  # Show the current input point
  if( @ip.valid? && @ip.display? )
    @ip.draw(view)
    @drawn = true
  end
  # show the rectangle
  if( @state == 1 )
    # just draw a line from the start to the end point
    view.set_color_from_line(@ip1, @ip)
    inference_locked = view.inference_locked?
    view.line_width = 3 if inference_locked
    view.draw(GL_LINE_STRIP, @pts[0], @pts[1])
    view.line_width = 1 if inference_locked
    @drawn = true
  elsif( @state ==2 )
    # draw the curve
    view.drawing_color = "black"
    view.draw(GL_LINE_STRIP, @pts)
    @drawn = true
  elsif( @state ==3 )
    # draw the box
    view.drawing_color = "black"
    view.draw(GL_LINE_STRIP, @pts)
    if(@extrudePoint!=nil && @depth>0)
      xform=Geom::Transformation.new(@extrudePoint-@center)
      tp=[]
      sp=[]
      @pts.each{|p|
        sp.push(p)
        sp.push(p.transform(xform))
        tp.push(p.transform(xform))
      }
      @bb.add sp
      @bb.add tp
      view.draw(GL_LINE_STRIP, tp)
      view.draw(GL_LINES, sp)
    end
    @drawn = true
  end
end

def onKeyDown(key, rpt, flags, view)
  if( key == CONSTRAIN_MODIFIER_KEY && rpt == 1 )
    @shift_down_time = Time.now

    # if we already have an inference lock, then unlock it
    if( view.inference_locked? )
      view.lock_inference
    elsif( @state == 0 )
      view.lock_inference @ip
    elsif( @state == 1 )
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

end # of class BoxPrimTool
end #module MSketchyPhysics3
