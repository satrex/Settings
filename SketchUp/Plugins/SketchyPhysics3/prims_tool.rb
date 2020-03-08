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
# Adapted from the sketchup example    Rotated Rectangle Tool 1.0
# Additions copyright Chris Phillips


require 'sketchup.rb'

module MSketchyPhysics3

  def self.setupBuoyancy
    # Look for existing water plane.
    grp = nil
    Sketchup.active_model.definitions.each { |cd|
      cd.instances.each { |ci|
        if ci.get_attribute('SPWATERPLANE', 'density', nil) != nil && !ci.deleted?
          grp = ci
          break
        end
      }
    }
    # If not found
    density = 1.0
    linearViscosity = 1.0
    angularViscosity = 1.0
    current = [0.0,0.0,0.0]
    if grp
      density = grp.get_attribute('SPWATERPLANE', 'density', 1.0)
      linearViscosity = grp.get_attribute('SPWATERPLANE', 'linearViscosity', 1.0)
      angularViscosity = grp.get_attribute('SPWATERPLANE', 'angularViscosity', 1.0)
      current = grp.get_attribute('SPWATERPLANE', 'current', [0.0,0.0,0.0])
    end
    enabled = true
    prompts = ["Enabled","Density", "Linear Viscosity", "Angular Viscosity","Current X","Current Y","Current Z"]
    promts = %w(Enabled Density Linear_Viscosity Angular_Viscosity Current_X Current_Y Current_Z)
    values = [enabled, density, linearViscosity, angularViscosity, current[0], current[1], current[2]]
    results = inputbox(prompts, values, ['true|false'], 'Buoyancy plane settings.')
    return unless results
    enabled, density, linearViscosity, angularViscosity, current[0], current[1], current[2] = results
    if enabled == false || enabled == 'false'
      grp.erase! if grp and grp.valid?
      return
    end
    unless grp
      grp = Sketchup.active_model.entities.add_group
      face = grp.entities.add_face([5000,5000,0], [-5000,5000,0], [-5000,-5000,0], [5000,-5000,0])
      grp.material = Sketchup.active_model.materials.add('water blue')
      grp.material.color = Sketchup::Color.new('Blue')
      grp.material.alpha = 0.6
      grp.set_attribute('SPOBJ', 'ignore', true)
    end
    grp.set_attribute('SPWATERPLANE', 'density', density)
    grp.set_attribute('SPWATERPLANE', 'linearViscosity', linearViscosity)
    grp.set_attribute('SPWATERPLANE', 'angularViscosity', angularViscosity)
    grp.set_attribute('SPWATERPLANE', 'current', current)
  end

class CreatePrimTool

  def get_input_point_normal(ip)
    if ip.face
      ip.face.normal.transform(ip.transformation)
    else
      if ip.position[2] == 0.0
      Geom::Vector3d.new(0,0,1)
      elsif ip.position[1] == 0.0
      Geom::Vector3d.new(0,1,0)
      elsif ip.position[0] == 0.0
      Geom::Vector3d.new(1,0,0)
      else
      Geom::Vector3d.new(0,0,1)
      end
    end
  end

  def create_sphere(rad, segs)
    grp = Sketchup.active_model.active_entities.add_group()
    ents = grp.entities
    #arc1 = ents.add_arc([0,0,0], [1,0,0], [0,1,0], rad, -90.degrees, 90.degrees)
    #faces = latheShape(rad, segs, edges)
    arc1 = arcPoints([0,0,0], [0,1,0], rad, -90.0, 90.0, 12)
    faces = lathePoints(rad, segs, arc1)
    for face in faces
      begin
        f = ents.add_face(face)
      rescue
        # Sort of a hack.
        face.delete_at(1) # Remove duplicate point.
        # And try again
        f = ents.add_face(face)
      end
      f.edges.each { |edge|
        edge.smooth=true
        edge.soft=true
      }
    end
    grp.name = 'sphere'
    grp
  end

  def arcPoints(center, normal, radius, start_angle, end_angle, numsegs)
    points = []
    inc = (end_angle-start_angle)/numsegs.to_f
    start_angle.step(end_angle, inc){ |r|
      pt = [radius,0,0]
      pt.transform!(Geom::Transformation.new(ORIGIN, normal, r.degrees))
      pt.transform!(Geom::Transformation.new(center))
      points.push(pt)
    }
    points
  end

  def lathePoints(rad, segs, points)
    faces = []
    inc = 360.0/segs
    0.step(360.0,inc){ |r|
      0.upto(points.length-2){ |pi|
        t1 = Geom::Transformation.new(ORIGIN, Z_AXIS, r.degrees)
        t2 = Geom::Transformation.new(ORIGIN, Z_AXIS, (r+inc).degrees)
        p1 = Geom::Point3d.new(points[pi])
        p2 = Geom::Point3d.new(points[pi+1])
        pa = [p1.transform(t1), p2.transform(t1), p2.transform(t2), p1.transform(t2)]
        pa.uniq!
        faces.push(pa)
      }
    }
    faces
  end

  def latheShape(rad, segs, edges)
    faces = []
    inc = 360.0/segs
    0.step(360.0,inc){ |r|
      for e in edges
        t1 = Geom::Transformation.new(ORIGIN, Z_AXIS, r.degrees)
        t2 = Geom::Transformation.new(ORIGIN, Z_AXIS, (r+inc).degrees)
        pa = [e.vertices[0].position.transform!(t1), e.vertices[1].position.transform!(t1),
           e.vertices[1].position.transform!(t2), e.vertices[0].position.transform!(t2)]
        pa.uniq!
        faces.push(pa)
      end
    }
    faces
  end

  def create_capsule(rad, hei, segs)
    grp = Sketchup.active_model.active_entities.add_group
    ents = grp.entities
    arc1 = ents.add_arc([0,0,rad], [1,0,0], [0,1,0], rad, 0.degrees, 90.degrees)
    arc2 = ents.add_arc([0,0,hei-rad], [1,0,0], [0,1,0], rad, 270.degrees, 360.degrees)
    line1 = ents.add_line(arc1[0].vertices[0], arc2[arc2.length-1].vertices[1])
    edges = arc1 + arc2 + [line1]
    faces = latheShape(rad, segs, edges)
    for face in faces
      begin
        f = ents.add_face(face)
      rescue
        # Sort of a hack.
        face.delete_at(1) # Remove duplicate point.
        # And try again
        f = ents.add_face(face)
      end
      f.edges.each { |edge|
        edge.smooth = true
        edge.hidden = true
      }
    end
    grp.name = 'capsule'
    grp
  end

  def create_chamfer(rad,hei,segs)
    grp = Sketchup.active_model.active_entities.add_group
    ents = grp.entities
    arc1 = ents.add_arc([-(rad-(hei/2)),0,hei/2], [1,0,0], [0,1,0], hei/2, 270.degrees, 90.degrees)
    line1=ents.add_line(arc1[0].vertices[0], [0,0,hei])
    line2=ents.add_line(arc1[arc1.length-1].vertices[1], [0,0,0])
    edges = arc1 + [line1, line2]
    faces = latheShape(rad, segs, edges)
    for face in faces
      begin
        f = ents.add_face(face)
      rescue
        # Sort of a hack.
        face.delete_at(1) # Remove duplicate point.
        # And try again
        f = ents.add_face(face)
      end
      f.edges.each{ |edge|
        edge.smooth = true
        edge.hidden = true
      }
    end
    grp.name = 'chamfer'
    grp
  end

  def create_cone(parentEnts, rad, hei, segs, taper)
    grp = parentEnts.add_group
    ents = grp.entities
    shape = sp_points_on_circle(ORIGIN, Z_AXIS, rad, segs, 0)
    ents.add_face(shape)
    if taper <= 0
      #topShape = sp_points_on_circle([0,0,@solidHeight], Z_AXIS, rad*@taper, segs, 0)
      #ents.add_face(topShape)
      0.step(shape.length-2, 1){ |pi|
        #puts shape[pi]
        f=ents.add_face(shape[pi], [0,0,hei], shape[pi+1])
        #f.edges.each{ |edge| edge.smooth = true; edge.soft = true }
        f.edges[2].smooth = true
        f.edges[2].soft = true
      }
      grp.name = 'cone'
    else
      topShape = sp_points_on_circle([0,0,hei], Z_AXIS, rad*taper, segs, 0)
      ents.add_face(topShape)
      0.step(shape.length-2, 1){ |pi|
        #puts shape[pi]
        f = ents.add_face(shape[pi], topShape[pi], topShape[pi+1], shape[pi+1])
        #f.edges.each{ |edge| edge.smooth = true; edge.soft = true }
        f.edges[0].smooth = true
        f.edges[0].soft = true
        #f.edges[3].smooth = true
        #f.edges[3].soft = true
        grp.name = 'cylinder'
      }
    end
    grp
  end

  # Function for generating points on a circle
  def sp_points_on_circle(center, normal, radius, numseg, rotAngle)
    # Get the x and y axes
    axes = Geom::Vector3d.new(normal).axes
    center = Geom::Point3d.new(center)
    xaxis = axes[0]
    yaxis = axes[1]
    xaxis.length = radius
    yaxis.length = radius
    rotAngle = 0.0 unless rotAngle.is_a?(Numeric)
    # Compute the points
    da = (Math::PI*2) / numseg
    pts = []
    for i in 0...numseg do
      angle = rotAngle + (i * da)
      cosa = Math.cos(angle)
      sina = Math.sin(angle)
      vec = Geom::Vector3d.linear_combination(cosa, xaxis, sina, yaxis)
      pts.push(center + vec)
    end
    # Close the circle
    pts.push(pts[0].clone)
    pts
  end

  def makeCustomCursor
    @customCursorLines = []
    MSketchyPhysics3.get_entities(Sketchup.active_model.selection[0]).each { |e|
      if e.is_a?(Sketchup::Edge)
        @customCursorLines.push([e.start.position, e.end.position])
        #@customCursorLines.push(e.end.position)
      end
    }
  end

  def initialize(primType, jointType)
    @primType = primType
    @taper = 1.0
    @numSegments = 16
    @defaultJointType = jointType
    @customCursorLines = []
    #makeCustomCursor()
    case primType
      when 'line'
      when 'cone'
        @taper = 0.0
      when 'box'
        @numSegments = 4
    end
    @ip = Sketchup::InputPoint.new
    reset
    #need_draw = true
  end

  def reset
    @inputPoints = []
    if (@centerLine != nil && !@centerLine.deleted?)
      @centerLine.erase!
      @centerLine = nil
    end
    #@drawn = false
    #Sketchup.set_status_text '', SB_VCB_LABEL
    #Sketchup.set_status_text '', SB_VCB_VALUE
    #Sketchup.set_status_text 'Click for start point'
    #Sketchup.active_model.abort_operation
  end

  def activate
    self.reset
    #Sketchup.active_model.start_operation 'Solid Tool'
  end

  def deactivate(view)
    reset
    #Sketchup.active_model.commit_operation
    view.invalidate
  end

  def getCurrentProfile(rad, hei)
    if @primType == 'chamfer' && @shapeRadius < hei
       @primType = 'capsule'
       #puts "Switch to #{@primType}"
    end
    if @primType == 'capsule' && hei < @shapeRadius*2
       @primType = 'chamfer'
       #puts "Switch to #{@primType}"
    end
    case @primType
      when 'sphere'
        edges = arcPoints([0,0,0], [0,1,0], rad, -90.0, 90.0, 12)
      when 'capsule'
        arc1 = arcPoints([0,0,rad], [0,1,0], rad, 0, 90, 6)
        arc2 = arcPoints([0,0,hei-rad], [0,1,0], rad, 270, 360, 6)
        line1 = [arc1[0], arc2[arc2.length-1]]
        edges = arc2+line1+arc1#+line1
      when 'chamfer'
        arc1 = arcPoints([-(rad-(hei/2)), 0, hei/2], [0,1,0], hei/2, 90, 270, 8)
        line1 = [arc1[0], [0,0,0]]
        line2 = [arc1[arc1.length-1], [0,0,hei]]
        edges = line1+arc1+line2
      when 'torus'
        arc1 = arcPoints([-(rad-(hei/2)),0,hei/2], [0,1,0], hei/2, 360, 0, 16)
        edges = arc1
    end
    edges
  end

  def previewLathedObject(view)
    if @solidHeight < 0
      #puts 'flip'
      #@solidHeight = -@solidHeight # Make sure object is not inside out.
      xform = Geom::Transformation.new(@inputPoints[0].position, get_input_point_normal(@inputPoints[0]).reverse)
    else
      xform = Geom::Transformation.new(@inputPoints[0].position, get_input_point_normal(@inputPoints[0]))
    end
    profile = getCurrentProfile(@shapeRadius, @solidHeight.abs)
    #view.draw(GL_LINE_STRIP, profile)
    if profile
      faces = lathePoints(@shapeRadius, 12, profile)
      #puts faces.size
      for f in faces
        f[0].transform!(xform)
        f[1].transform!(xform)
        f[2].transform!(xform)
        f[3].transform!(xform)
        view.draw(GL_LINE_STRIP, f)
      end
    end
  end

  def createLathedObject(parentEnts)
    grp = parentEnts.add_group
    ents = grp.entities
    profile = getCurrentProfile(@shapeRadius, @solidHeight.abs)
    faces = lathePoints(@shapeRadius, 12, profile)
    for face in faces
      begin
        f = ents.add_face(face)
      rescue
        # Sort of a hack.
        face.delete_at(1) # Remove duplicate point.
        # And try again
        begin
        f = ents.add_face(face)
        rescue
        end
      end
      f.edges.each { |edge|
        edge.smooth = true
        edge.soft = true
      }
    end
    grp
  end

  def calcExtrudePoint(view)
    normal = get_input_point_normal(@inputPoints[0])
    center = @inputPoints[0].position
    vp = @ip.position
    # If not on a valid point then infer position in screen space.
    unless @ip.display?
      # Line from center of shape "up" along its normal.
      la = [center, normal]
      # Line from eye to 3dpoint under cursor.
      lb = [view.camera.eye, @ip.position]
      #view.draw(GL_LINE_STRIP, Geom.closest_points(la, lb))
      # If not on a valid point then infer position in screen space.
      vp = Geom.closest_points(la, lb)[0]
      #view.draw_points(vp, 2, 1, 'red')
    end
    # Limit extrude to the normal direction.
    ep = vp.project_to_line([center, normal])
    ep
  end

  def previewShapeCursor(view)
    if get_input_point_normal(@ip)
      pts = sp_points_on_circle(@ip.position, get_input_point_normal(@ip), 3, @numSegments, 0)
      view.draw(GL_LINE_STRIP, pts)

      #~ pts = sp_points_on_circle(@ip.position, get_input_point_normal(@ip), 1.25, @numSegments, 0)
      #~ view.draw(GL_LINE_STRIP, pts)

      #~ xform=Geom::Transformation.new(@ip.position, get_input_point_normal(@ip))
      #~ @customCursorLines.each { |a,b|
        #~ view.draw_line(a.transform(xform), b.transform(xform))
      #~ }
      #puts @customCursorLines
      #if (@customCursorLines != nil && @customCursorLines.length > 0)
      #   view.draw_lines(@customCursorLines)
      #end
    end
  end

  def previewSphere(view)
    previewShape(view)
    if @shapeRadius
      0.step(180,30){ |r|
        center = @inputPoints[0].position
        unless @ctrlDown
          n = get_input_point_normal(@inputPoints[0])
          n.length = @shapeRadius
          center = @inputPoints[0].position+n
        end
        rn = get_input_point_normal(@inputPoints[0]).transform(Geom::Transformation.rotation([0,0,0], [0,1,0], r.degrees))
        view.draw(GL_LINE_STRIP, sp_points_on_circle(center, rn, @shapeRadius, @numSegments, 0))
        rn = get_input_point_normal(@inputPoints[0]).transform(Geom::Transformation.rotation([0,0,0], [1,0,0], r.degrees))
        view.draw(GL_LINE_STRIP,sp_points_on_circle(center, rn, @shapeRadius, @numSegments, 0))
      }
    end
  end

  def previewRectangle(view)
    corner1 = @inputPoints[0].position
    normal = get_input_point_normal(@inputPoints[0])
  end

  def previewShape(view)
    center = @inputPoints[0].position
    normal = get_input_point_normal(@inputPoints[0])

    # Project the input point on a plane described by our normal and center.
    vp = @ip.position
    # ???? is this needed.
    ep = vp.project_to_plane([center,normal])
    # ????

    ep = Geom.intersect_line_plane([view.camera.eye, @ip.position], [center,normal])

    view.set_color_from_line(center, ep)
    view.draw(GL_LINE_STRIP, [center,ep])

    dir = center.vector_to(ep).normalize
    forward = normal.axes[0]
    angleDelta = forward.angle_between(dir)

    dot = forward.dot(dir)
    #angleDelta = Math.acos(dot)
    #puts dot < 0 ? angleDelta : -angleDelta
    radius = center.distance(ep)
    angleDelta = 0
    #center = @ip.position if @ctrlDown

    @shapePoints = sp_points_on_circle(center, get_input_point_normal(@inputPoints[0]), radius, @numSegments, angleDelta)
    @shapeRadius = radius

    view.drawing_color = 'blue'
    view.draw(GL_LINE_STRIP, @shapePoints)
  end

  def previewTaper(view)
    center = @inputPoints[0].position
    normal = get_input_point_normal(@inputPoints[0])

    # Project the input point on a plane described by our normal and center.
    vp = @ip.position
    ep = vp.project_to_plane([center,normal])

    ep = Geom.intersect_line_plane([view.camera.eye, @ip.position], [center,normal])

    view.set_color_from_line(center, ep)
    view.draw(GL_LINE_STRIP, [center,ep])

    dir = center.vector_to(ep).normalize
    forward = normal.axes[0]
    angleDelta = forward.angle_between(dir)

    dot = forward.dot(dir)
    #angleDelta = Math.acos(dot)
    #puts dot < 0 ? angleDelta : -angleDelta
    radius = center.distance(ep)
    angleDelta = 0
    #center = @ip.position if @ctrlDown

    @shapePoints = sp_points_on_circle(center, get_input_point_normal(@inputPoints[0]), radius, @numSegments, angleDelta)
    @shapeRadius = radius

    view.drawing_color = 'blue'
    view.draw(GL_LINE_STRIP, @shapePoints)
  end

  def previewSolid(view)
    normal = get_input_point_normal(@inputPoints[0])
    center = @inputPoints[0].position
    ep = calcExtrudePoint(view)
    view.line_stipple = '-.-'
    view.draw(GL_LINE_STRIP, [@ip.position,ep])
    view.line_stipple = ''
    @solidHeight = ep.distance(center)
    if Geom::Vector3d.new((ep-center).to_a).dot(normal) < 0
      @solidHeight = -@solidHeight
    end
    if %w(capsule chamfer torus).include?(@primType)
      previewLathedObject(view)
      return
    end
    topShape = nil
    view.drawing_color = 'purple'
    view.draw(GL_LINE_STRIP, @shapePoints)
    topShape = sp_points_on_circle(ep, normal, @shapeRadius*@taper, @numSegments, 0)
    view.draw(GL_LINE_STRIP, topShape)
    i = 0
    @shapePoints.each { |v|
      #view.draw(GL_LINE_STRIP, [v, ep])
      view.draw(GL_LINE_STRIP, [v, topShape[i]])
      i += 1
    }
  end

  def drawPreviewShape(view)
    @bDrawPoint = true
    view.draw_points(@ip.position, 2, 1, 'red') if @bDrawPoint

    @bDrawLine = true
    if @bDrawLine && @inputPoints.length > 0
      #view.draw(GL_LINE_STRIP, [@inputPoints[0].position, @ip.position])
    end

    @bDrawNormal = true
    if @bDrawNormal && get_input_point_normal(@ip) != nil
      normal = get_input_point_normal(@ip)
      normal.length = 3
      view.draw(GL_LINE_STRIP, [@ip.position, @ip.position+get_input_point_normal(@ip)])
    end

    case @primType
      when 'line'
        if @ctrlDown
          view.draw(GL_LINE_STRIP, [@inputPoints[0].position, @inputPoints[0].position-(@ip.position-@inputPoints[0].position)])
        end
      when 'sphere'
        if @inputPoints.length == 0
          previewShapeCursor(view)
        elsif @inputPoints.length == 1
          previewSphere(view)
        end
      when 'box'
        if @inputPoints.length == 0
          if @ctrlDown
            view.draw(GL_LINE_STRIP, [@inputPoints[0].position, @inputPoints[0].position-(@ip.position-@inputPoints[0].position)])
          end
        elsif @inputPoints.length == 1
          previewRectange(view)
        elsif @inputPoints.length == 2
          previewSolid(view)
        elsif @inputPoints.length == 3
          previewTaper(view)
        end
      when 'cylinder', 'chamfer', 'capsule', 'torus'
        if @inputPoints.length == 0
          previewShapeCursor(view)
        elsif @inputPoints.length == 1
          previewShape(view)
        elsif @inputPoints.length == 2
          previewSolid(view)
        elsif @inputPoints.length == 3
          previewTaper(view)
        end
      when 'cone'
        if @inputPoints.length == 0
          previewShapeCursor(view)
        elsif @inputPoints.length == 1
          previewShape(view)
        elsif @inputPoints.length == 2
          previewSolid(view)
        elsif @inputPoints.length == 3
          previewTaper(view)
        end
    end
  end

  def draw(view)
    # Show the current input point
    @ip.draw(view) #if (@ip.valid? && @ip.display?)
    # Just draw a line from the start to the end point
    if @inputPoints[0]
      #view.set_color_from_line(@inputPoints[0], @ip)
    end
    inference_locked = view.inference_locked?
    view.line_width = 1
    view.line_width = 3 if inference_locked

    drawPreviewShape(view)

    view.line_width = 1 if inference_locked
    @drawn = true
  end

  def onMouseMove(flags, x, y, view)
    #self.set_current_point(x, y, view)
    state = @ip.pick(view, x, y)
    #return false unless state
    view.invalidate #if @ip.display?
  end

  def onLButtonDown(flags, x, y, view)
    #self.set_current_point(x, y, view)
    #self.increment_state

    state = @ip.pick(view, x, y)
    #return false unless state

    ti = Sketchup::InputPoint.new
    ti.copy! @ip
    @inputPoints.push(ti)

    if @inputPoints.length == 1
      ph = view.pick_helper
      num = ph.do_pick x,y
      ent = ph.best_picked
      if (ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance))
        @potentialParent = ent
        puts "Potential Parent: #{ent}"
      else
        @potentialParent = nil
      end
    end

    model = Sketchup.active_model

    case @primType
      when 'line'
        if @inputPoints.length == 2
          model.abort_operation
          if Sketchup.version.to_i > 6
            model.start_operation('Create SketchyLine', true)
          else
            model.start_operation('Create SketchyLine')
          end
          if @ctrlDown
            model.entities.add_line(@inputPoints[0].position,
              @inputPoints[0].position-(@ip.position-@inputPoints[0].position))
          end
          model.entities.add_line(@inputPoints[0].position.to_a, @inputPoints[1].position.to_a)
          model.commit_operation
          self.reset
        end
      when 'cylinder'
        if @inputPoints.length == 2
          if Sketchup.version.to_i > 6
            model.start_operation('Solid Tool', true)
          else
            model.start_operation('Solid Tool')
          end
          @centerLine = model.entities.add_cline(@inputPoints[0].position, get_input_point_normal(@inputPoints[0]))
        end
      when 'box'
        if @inputPoints.length == 2
          if Sketchup.version.to_i > 6
            model.start_operation('Solid Tool', true)
          else
            model.start_operation('Solid Tool')
          end
          @centerLine = model.entities.add_cline(@inputPoints[0].position, get_input_point_normal(@inputPoints[0]))
        end
      when 'cone', 'chamfer', 'capsule', 'torus'
        if @inputPoints.length == 2
          if Sketchup.version.to_i > 6
            model.start_operation('Solid Tool', true)
          else
            model.start_operation('Solid Tool')
          end
          @centerLine = model.entities.add_cline(@inputPoints[0].position, get_input_point_normal(@inputPoints[0]))
        end
      when 'sphere'
        if @inputPoints.length == 1
          Sketchup.set_status_text 'Hold CTRL to change centering.'
        end
        if @inputPoints.length == 2
          model.abort_operation
          if Sketchup.version.to_i > 6
            model.start_operation("Create #{@primType}", true)
          else
            model.start_operation("Create #{@primType}")
          end
          grp = create_sphere(@shapeRadius, @numSegments)
          grp.set_attribute('SPOBJ', 'shape', 'sphere')
          center = @inputPoints[0].position
          unless @ctrlDown
            n = get_input_point_normal(@inputPoints[0])
            n.length = @shapeRadius
            center = @inputPoints[0].position+n
          end
          # SP4 experimental
          #~ grp.set_attribute('SPJOINT', 'type', 'ball') if @ctrlDown
          grp.transform!(Geom::Transformation.new(center, get_input_point_normal(@inputPoints[0])))
          if model.materials.current != nil
            #model.materials.each { |m| puts m.name }
            #model.materials.current = model.materials.current
            #grp.material = model.materials.current
          end
          model.commit_operation
          model.selection.clear
          model.selection.add(grp)
          # Sketchup.active_model.select_tool(CreateJointTool.new('servo'))
          self.reset
          #Sketchup.active_model.select_tool nil
          view.lock_inference
        end
    end

    if @inputPoints.length == 3
      if @solidHeight == 0
        @inputPoints.pop
        return
      end

      #preloadJoint(@defaultJointType) if (@potentialParent != nil && @defaultJointType != nil)
      model.abort_operation

      if Sketchup.version.to_i > 6
        model.start_operation("Create #{@primType}", true)
      else
        model.start_operation("Create #{@primType}")
      end
      parent = nil
      if (@potentialParent != nil && @defaultJointType != nil)
        parent = model.active_entities.add_group
        parentEnts = parent.entities
      else
        parentEnts = model.active_entities
      end

      #parent = model.active_entities.add_group
      case @primType
        when 'cone'
          grp = create_cone(parentEnts, @shapeRadius, @solidHeight.abs, @numSegments, @taper)
          # SP4 experimental
          #~ if @ctrlDown
            #~ grp.set_attribute('SPJOINT', 'type', 'servo')
            #~ grp.set_attribute('SPJOINT', 'rotlimits', [-90.degrees,90.degrees, 0.0,0.0, 0.0,0.0 ,1.0,0.0])
            #~ grp.set_attribute('SPJOINT', 'linlimits', [0.0,0.0, 0.0,0.0, 0.0,0.0 ,0.0,0.0])
          #~ end
        when 'cylinder'
          grp = create_cone(parentEnts, @shapeRadius, @solidHeight.abs, @numSegments, @taper)
          # SP4 experimental
          #~ if @ctrlDown
            #~ grp.set_attribute('SPJOINT', 'type', 'slider')
          #~ end
        when 'chamfer', 'capsule', 'torus'
          grp = createLathedObject(parentEnts)
          # SP4 experimental
          #~ if @ctrlDown
            #~ grp.set_attribute('SPJOINT', 'type', 'hinge')
          #~ end
      end
      # Set random material.
      #~ materials = model.materials
      #~ if materials.length > 0
        #~ grp.material = materials[rand(materials.length)]
      #~ end
      if @solidHeight < 0
        xform = Geom::Transformation.new(@inputPoints[0].position, get_input_point_normal(@inputPoints[0]).reverse)
      else
        xform = Geom::Transformation.new(@inputPoints[0].position, get_input_point_normal(@inputPoints[0]))
      end
      grp.set_attribute('SPOBJ', 'shape', @primType)
      grp.name = @primType
      grp.transform!(xform)
      model.commit_operation

      if (@potentialParent != nil && @defaultJointType != nil)
        vlen = get_input_point_normal(@inputPoints[0])
        vlen.length = @solidHeight
        jnt = MSketchyPhysics3.makePhysicsJoint(@defaultJointType, @inputPoints[0].position+vlen, @inputPoints[0].position, parent.entities)
        puts "Attach to: #{@potentialParent}"
        JointConnectionTool.connectJoint(jnt, @potentialParent)
        model.selection.clear
        model.selection.add(parent)
      else
        model.selection.clear
        model.selection.add(grp)
      end
      self.reset
      #model.select_tool nil
      view.lock_inference
    end
  end

  def onCancel(flag, view)
    view.invalidate if @drawn
    self.reset
  end

  def makePhysicsPrim(pt1, pt2)
    @baseFace.outer_loop.vertices.each { |v|
      Sketchup.active_model.entities.add_line(v.position.to_a, @ip.position.to_a)
    }
    return
    depth = pt1.distance pt2
    group = Sketchup.active_model.active_entities.add_group
    circle = group.entities.add_circle([0,0,0], [0,0,1], 0.5, 8)
    base = group.entities.add_face circle
    depth = -depth if base.normal.dot(Z_AXIS) < 0.0
    base.pushpull depth

    v = Geom::Vector3d.new(pt2.x-pt1.x, pt2.y-pt1.y, pt2.z-pt1.z)
    a = v.axes
    t = Geom::Transformation.new(a[0], a[1], a[2], pt1)
    group.transform!(t)
    group
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
    # Process here.
    @numSegments = value
  end

  def getExtents
    bb = Geom::BoundingBox.new
    bb.add @ip.position
    bb.add @ip.position
    # TODO: fix this!
    return

    bb = Geom::BoundingBox.new
    case @state
    when 0
      # We are getting the first point
      if (@ip.valid? && @ip.display?)
        bb.add @ip.position
      end
    when 1
      bb.add @pts[0]
      bb.add @pts[1]
    when 2
      bb.add @pts
    end
    bb
  end

  def onKeyDown(key, rpt, flags, view)
    if (key == COPY_MODIFIER_KEY && rpt == 1)
      @ctrlDown = true
    end
    if (key == CONSTRAIN_MODIFIER_KEY && rpt == 1)
      @shift_down_time = Time.now
      return
      # if we already have an inference lock, then unlock it
      if view.inference_locked?
        view.lock_inference
      elsif @inputPoints.length == 0
        view.lock_inference @ip
      elsif @inputPoints.length == 2
        view.lock_inference @ip, @inputPoints[0]
      end
    end
    view.invalidate
  end

  def onKeyUp(key, rpt, flags, view)
    if key == COPY_MODIFIER_KEY
      @ctrlDown = false
    end
    if( key == CONSTRAIN_MODIFIER_KEY &&
      view.inference_locked? &&
      (Time.now - @shift_down_time) > 0.5 )
      view.lock_inference
    end
    view.invalidate
  end

end # class CreatePrimTool


  def self.createPhysicsFloor
    dir = File.dirname(__FILE__)
    path = File.join(dir, 'components/floor.skp')
    return unless File.exists?(path)
    cd = Sketchup.active_model.definitions.load(path)
    if cd
      grp = Sketchup.active_model.entities.add_instance(cd, Geom::Transformation.new())
      grp.set_attribute('SPOBJ', 'shape', 'staticmesh')
      grp.set_attribute('SPOBJ', 'staticmesh', true)
    end
    grp
  end

  def self.createPrim(type)
    model = Sketchup.active_model
    case type.to_s.downcase
    when 'box'
      model.select_tool BoxPrimTool.new(nil)
    when 'door'
      model.select_tool BoxPrimTool.new('hinge')
    when 'arm'
      model.select_tool BoxPrimTool.new('servo')
    when 'lift'
      model.select_tool CreatePrimTool.new('chamfer', 'slider')
    when 'wheel'
      model.select_tool CreatePrimTool.new('chamfer', 'hinge')
    else
      model.select_tool CreatePrimTool.new(type.to_s, nil)
    end
  end

end # module MSketchyPhysics3
