=begin
Name:         ae_WireTool.rb
Author:       Andreas Eisenbarth
Description:  This Plugin allows to draw physically correct wires with only two clicks.
Usage:        menu Plugins → Draw Wires
              Type a number + "s" to change the number of curve segments:
                24s
              Type a number + "%" to set an arc length (relative to the distance between source and target point):
                120%
              Type a length to set a fixed arc length:
                72.5m
                30.66"
Version:      1.4.1
Date:         06.03.2012

This plugin is largely based on Google's LineTool, modified to draw catenary curves instead of straight lines.
---------------------------------------------------------------------------
Copyright 2005-2008, Google, Inc.

This software is provided as an example of using the Ruby interface
to SketchUp.

Permission to use, copy, modify, and distribute this software for
any purpose and without fee is hereby granted, provided that the above
copyright notice appear in all copies.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
-----------------------------------------------------------------------------
=end



require 'sketchup.rb'



module AE



class WireTool

@@dir = File.dirname(__FILE__)
@@language_strings = {
  "en" => {
    "Draw Wires" => "Draw Wires",
    "Catenary" => "Catenary",
    "Tool to draw catenary curves." => "Tool to draw catenary curves.",
    "Arc Length" => "Arc Length",
    "Segments" => "Segments",
    "Distance" => "Distance",
    "Select first end" => "Select first end",
    "Select second end" => "Select second end"
  },
  "de" => {
    "Draw Wires" => "Seile zeichnen",
    "Catenary" => "Katenoid",
    "Tool to draw catenary curves." => "Werkzeug zum Zeichnen von katenoiden Kurven.",
    "Arc Length" => "Bogenlänge",
    "Segments" => "Seiten",
    "Distance" => "Abstand",
    "Select first end" => "Wählen Sie einen Anfangspunkt aus",
    "Select second end" => "Wählen Sie einen Endpunkt aus"
  },
  "fr" => {
    "Draw Wires" => "Dessiner des cables",
    "Catenary" => "Chaînette",
    "Tool to draw catenary curves." => "Outil pour dessiner des courbes des chaînes ou câbles.",
    "Arc Length" => "Longueur d'un arc",
    "Segments" => "Segments",
    "Distance" => "Distance",
    "Select first end" => "Sélectionnez le point de départ",
    "Select second end" => "Sélectionnez le point d'arrivée"
  },
  "es" => {
    "Draw Wires" => "Dibujar Cables",
    "Catenary" => "Catenaria",
    "Tool to draw catenary curves." => "Herramienta para dibujar curvas catenarias.",
    "Arc Length" => "Longitud Arco",
    "Segments" => "Segmentos",
    "Distance" => "Distancia",
    "Select first end" => "Selecciona Primer Final",
    "Select second end" => "Selecciona Segundo Final"
  }
}
@@curve_length_mode ||= 0      # 0 = percent, 1 = fixed length
@@curve_length_percent ||= 110 # percent value
@@curve_length ||= 1.m         # fixed length value
@@curve_segments ||= 12
@@segment_distribution_mode ||= 0 # 0 = equal horizontal distance between segments
                                  # 1 = equal segment lengths
                                  # 2 = equal angles between segments (visually best results)


# This is the standard Ruby initialize method that is called when you create
# a new object.
def initialize
  @ip1 = nil
  @ip2 = nil
  @state = 0
  @xdown = 0
  @ydown = 0
  @cursor_id = UI.create_cursor(File.join(@@dir, "cursor.png"), 0, 1)
end

# The activate method is called by SketchUp when the tool is first selected.
# it is a good place to put most of your initialization
def activate
  # The Sketchup::InputPoint class is used to get 3D points from screen
  # positions.  It uses the SketchUp inferencing code.
  # In this tool, we will have two points for the endpoints of the line.
  @ip1 = Sketchup::InputPoint.new
  @ip2 = Sketchup::InputPoint.new
  @ip = Sketchup::InputPoint.new

  @drawn = false

  # This sets the label for the VCB
  value = (@@curve_length_mode == 0)? @@curve_length_percent.to_s+"%" : @@curve_length
  Sketchup.set_status_text(@@translate["Arc Length"], SB_VCB_LABEL)
  Sketchup.set_status_text(value, SB_VCB_VALUE)

  reset(nil)
end


# deactivate is called when the tool is deactivated because
# a different tool was selected
def deactivate(view)
  view.invalidate if @drawn
end


# The onMouseMove method is called whenever the user moves the mouse.
# because it is called so often, it is important to try to make it efficient.
# In a lot of tools, your main interaction will occur in this method.
def onMouseMove(flags, x, y, view)
  if( @state == 0 )
    # We are getting the first end of the line.  Call the pick method
    # on the InputPoint to get a 3D position from the 2D screen position
    # that is bassed as an argument to this method.
    @ip.pick view, x, y
    if( @ip != @ip1 )
      # if the point has changed from the last one we got, then
      # see if we need to display the point.  We need to display it
      # if it has a display representation or if the previous point
      # was displayed.  The invalidate method on the view is used
      # to tell the view that something has changed so that you need
      # to refresh the view.
      view.invalidate if( @ip.display? or @ip1.display? )
      @ip1.copy! @ip

      # set the tooltip that should be displayed to this point
      view.tooltip = @ip1.tooltip
    end
  else
    # Getting the second end of the line
    # If you pass in another InputPoint on the pick method of InputPoint
    # it uses that second point to do additional inferencing such as
    # parallel to an axis.
    @ip2.pick view, x, y, @ip1
    view.tooltip = @ip2.tooltip if( @ip2.valid? )
    view.invalidate

    # Update the length displayed in the VCB
    if( @ip2.valid? )
      length = @ip1.position.distance(@ip2.position)
      Sketchup.set_status_text(@@translate["Distance"], SB_VCB_LABEL)
      Sketchup.set_status_text(length.to_s, SB_VCB_VALUE)
    end

    # Check to see if the mouse was moved far enough to create a line.
    # This is used so that you can create a line by either draggin
    # or doing click-move-click
    if( (x-@xdown).abs > 10 || (y-@ydown).abs > 10 )
      @dragging = true
    end
  end
end


# The onLButtonDOwn method is called when the user presses the left mouse button.
def onLButtonDown(flags, x, y, view)
  # When the user clicks the first time, we switch to getting the
  # second point.  When they click a second time we create the line
  if( @state == 0 )
    @ip1.pick view, x, y
    if( @ip1.valid? )
      @state = 1
      Sketchup.set_status_text(@@translate["Select second end"], SB_PROMPT)
      @xdown = x
      @ydown = y
    end
  else
    # create the line on the second click
    if( @ip2.valid? )
      create_geometry(@ip1.position, @ip2.position,view)
      reset(view)
    end
  end

  # Clear any inference lock
  view.lock_inference
end


# The onLButtonUp method is called when the user releases the left mouse button.
def onLButtonUp(flags, x, y, view)
  # If we are doing a drag, then create the line on the mouse up event
  if( @dragging && @ip2.valid? )
    create_geometry(@ip1.position, @ip2.position,view)
    reset(view)
  end
end


# onKeyDown is called when the user presses a key on the keyboard.
# We are checking it here to see if the user pressed the shift key
# so that we can do inference locking
def onKeyDown(key, repeat, flags, view)
  if( key == CONSTRAIN_MODIFIER_KEY && repeat == 1 )
    @shift_down_time = Time.now

    # if we already have an inference lock, then unlock it
    if( view.inference_locked? )
      # calling lock_inference with no arguments actually unlocks
      view.lock_inference
    elsif( @state == 0 && @ip1.valid? )
      view.lock_inference @ip1
    elsif( @state == 1 && @ip2.valid? )
      view.lock_inference @ip2, @ip1
    end
  end
end


# onKeyUp is called when the user releases the key
# We use this to unlock the interence
# If the user holds down the shift key for more than 1/2 second, then we
# unlock the inference on the release.  Otherwise, the user presses shift
# once to lock and a second time to unlock.
def onKeyUp(key, repeat, flags, view)
  if( key == CONSTRAIN_MODIFIER_KEY &&
    view.inference_locked? &&
    (Time.now - @shift_down_time) > 0.5 )
    view.lock_inference
  end
end


# onUserText is called when the user enters something into the VCB
# In this implementation, we set the vertical curvature of the arc
# either by percent of the length or by a fixed height.
def onUserText(text, view)
  # Setting the number of segments
  if text[/s$/]
    @@curve_segments = text[/[0-9]+/].to_i
    Sketchup.set_status_text(@@translate["Segments"], SB_VCB_LABEL)
    Sketchup.set_status_text(@@curve_segments, SB_VCB_VALUE)
  # Setting a percent value (overlength)
  elsif text[/\%$/]
    @@curve_length_mode = 0 # 0 = percent, 1 = fixed length
    value = text.sub(/,/,".")[/[0-9\-+\.]+/].to_f
    @@curve_length_percent = (value>100)? value : 100 # can't be shorter than shortest distance
    Sketchup.set_status_text(@@translate["Arc Length"], SB_VCB_LABEL)
    Sketchup.set_status_text(@@curve_length_percent.to_s+"%", SB_VCB_VALUE)
  # Setting a fixed length
  else
    @@curve_length_mode = 1 # 0 = percent, 1 = fixed length
    # The user may type in something that we can't parse as a length
    # so we set up some exception handling to trap that
    begin
      value = text.to_l
      @@curve_length = value if value.to_f > 0
      Sketchup.set_status_text(@@translate["Arc Length"], SB_VCB_LABEL)
      Sketchup.set_status_text(@@curve_length, SB_VCB_VALUE)
    rescue
      # Error parsing the text
      UI.beep
      puts("ae_WireTool: Cannot convert #{text} to a Length")
      value = nil
      Sketchup.set_status_text("", SB_VCB_VALUE)
    end
  end
end


def onSetCursor
  # You would set your cursor here. See UI.set_cursor method.
  UI.set_cursor(@cursor_id)
end


# The draw method is called whenever the view is refreshed.  It lets the
# tool draw any temporary geometry that it needs to.
def draw(view)
  if( @ip1.valid? )
    if( @ip1.display? )
      @ip1.draw(view)
      @drawn = true
    end

    if( @ip2.valid? )
      @ip2.draw(view) if( @ip2.display? )

      # The set_color_from_line method determines what color
      # to use to draw a line based on its direction.  For example
      # red, green or blue.
      view.set_color_from_line(@ip1, @ip2)
      draw_geometry(@ip1.position, @ip2.position, view)
      @drawn = true
    end
  end
end


# onCancel is called when the user hits the escape key
def onCancel(flag, view)
  reset(view)
end


private
# The following methods are not directly called from SketchUp.  They are
# internal methods that are used to support the other methods in this class.

# Reset the tool back to its initial state
def reset(view)
  # This variable keeps track of which point we are currently getting
  @state = 0
  # Display a prompt on the status bar
  Sketchup.set_status_text(@@translate["Select first end"], SB_PROMPT)
  # clear the InputPoints
  @ip1.clear
  @ip2.clear
  if( view )
    view.tooltip = nil
    view.invalidate if @drawn
  end
  @drawn = false
  @dragging = false
end


def get_curve_length(p0, p1)
  # curve length is percent of distance
  if @@curve_length_mode==0
    s = p0.distance(p1)*@@curve_length_percent/100.0
  # fixed curve length
  else
    # p1 can't be further away than curve length
    if p0.distance(p1) > @@curve_length
      vec = p0.vector_to(p1)
      vec.length = @@curve_length
      p1 = p0 + vec
    end
    s = @@curve_length
  end
  return s
end


# Create new geometry when the user has selected two points.
def create_geometry(p0, p1, view)
  s = get_curve_length(p0, p1)
  return if s == 0
  curve = catenary(p0, p1, s, @@curve_segments)
  view.model.active_entities.add_curve(curve) if curve
end


# Draw the geometry
def draw_geometry(p0, p1, view)
  s = get_curve_length(p0, p1)
  return if s == 0
  curve = catenary(p0, p1, s, @@curve_segments)
  view.draw_polyline(curve) if curve
end


# Calculate a catenary curve.
# @param [Geom::Point3d] p0  the start point
# @param [Geom::Point3d] p1  the end point
# @param [Numeric] s  arc length of the catenary
# @param [Fixnum] segments  the amount of edges of the catenary
# @returns [Array<Geom::Point3d>] an array of points if successful, otherwise nil
#
def catenary(p0, p1, s=p0.distance(p1), segments=12)
  segments = 1 if segments < 1
  # Vertical distance.
  v = p1.z - p0.z
  # Draw always from lower to higher point so that segment width is correct.
  (p0, p1 = p1, p0; v *= -1) if v < 0
  return if v > s
  # Horizontal distance.
  p2 = [p1.x, p1.y, p0.z]
  h = p0.distance(p2)
  # Diagonal distance.
  dp = p0.distance(p1)

  # Formula of catenary curve (http://en.wikipedia.org/wiki/Catenary):
  #   f(x) = a * cosh( (x-x0)/a ) + y0
  # Whereof <a> satisfies the equation (http://en.wikipedia.org/wiki/Catenary#Determining_parameters)
  #   (s² - v²)^0.5 = 2 * a * sinh( h/(2a) )

  # Numeric solution for <a>:
  # When curve length is set to 100% (straight line), the algorithm needs more
  # iterations to produce a straight line (it would have little sagging).
  max_iterations = 10 # to stop the recursion if something goes wrong.
  # The limit up to which precision the iteration goes.
  min_error = 0.001
  a = 100
  e = Float::MAX
  iteration = 0
  q = 0.1 / [s/dp-1, 0.00001].max # Magic: This scalar is big if the curve length is near 1 (almost straight line).
  until e < min_error || iteration >= max_iterations # error < 1‰ should be achieved in < 10 iterations
    iteration += 1
    a2 = 0.5 * h / ( Math.asinh( 0.5 * Math.sqrt(s**2-v**2) / a ) )
    e = ((a2-a)/a).abs
    a2 = a2 - q * (a-a2) # Magic: This increases the approximation step for small s/dp ratios and reaches faster the convergence.
    a = a2
  end

  # Numerical solution for <x0> (Newton):
  x0 = 0
  e = Float::MAX
  iteration = 0
  until e < min_error || iteration >= max_iterations # error < 1‰ should be achieved in < 10 iterations
    iteration += 1
    x02 = x0 + a*(   ( Math.cosh((0-x0)/a) - Math.cosh((h-x0)/a) + (v-0)/a ) / ( Math.sinh((0-x0)/a) - Math.sinh((h-x0)/a) )   )
    e = ((x02-x0)/x0).abs
    x0 = x02
  end
  # Solution for <y0>:
  y0 = - a * Math.cosh( (0-x0)/a )

  # Now we can calculate the points:
  vec = p0.vector_to(p2).normalize # horizontal vector towards target
  return nil if !vec.valid?
  point_array = []
  # Equal horizontal distances between segments.
  if @@segment_distribution_mode == 0
    d = h/segments.to_f
    (segments+1).times{|i|
      x = i * d
      y = a * Math.cosh( (x-x0)/a ) + y0
      p = p0 + sc(vec,x)
      p.z = p0.z + y
      point_array << p
    }
  # Equal segment lengths.
  elsif @@segment_distribution_mode == 1
    ds = s/segments.to_f
    (segments+1).times{|i|
      si = i * ds
      # Get the x value where the curve length has reached the length si.
      # Length of a catenary: s(0,x) = a * sinh(x/a)
      x = a * Math.asinh(si/a - Math.sinh(x0/a)) + x0 # the inverse function of the curve length, considering offset x0
      y = a * Math.cosh( (x-x0)/a ) + y0
      p = p0 + sc(vec,x)
      p.z = p0.z + y
      point_array << p
    }
  # TODO: This algorithm is BUGGED and I didn't find a solution yet.
  # It is noticeable with longer curve length (>200%) that the first and last
  # segments are too long and have too hard angles. The code below wrongly assumes
  # that we can insert vertices at every point where the slope has changed by a
  # certain angle.
  # Equal angles between segments (visually best result).
  elsif @@segment_distribution_mode == 2
    angle0 = Math.atan( Math.sinh((0-x0)/a) ).radians
    angle1 = Math.atan( Math.sinh((h-x0)/a) ).radians
    angle = (angle1 - angle0)/(segments+1).to_f
    (segments+1).times{|i|
      slope = Math.tan((angle0 + i * angle).degrees)
      # Get the x value where the slope of the curve has changed by i * angle.
      # Derivative: f'(x) = sinh( (x-x0)/a )
      x = a * Math.asinh( slope ) + x0 # the inverse function of the derivative
      y = a * Math.cosh( (x-x0)/a ) + y0
      p = p0 + sc(vec, x)
      p.z = p0.z + y
      point_array << p
    }
=begin
    p_1 = Geom::Point3d.new(x0, 0, y0) #p0.clone
    slope_1 = Math.tan((angle0).degrees) #Math.sinh((0-x0)/a)
    p_2 = nil
    slope_2 = nil
    (segments).times{|i|
      #b = (i == 0 || i == segments-1) ? 1.5 : 1
      b = (i == 0 || i == segments-1) ? 0.01 : 1
      slope_2 = Math.tan((angle0 + (i + b) * angle).degrees)
      # Get the x value where the slope of the curve has changed by i * angle.
      # Derivative: f'(x) = sinh( (x-x0)/a )
      x_2 = a * Math.asinh( slope_2 ) + x0 # the inverse function of the derivative
      y_2 = a * Math.cosh( (x_2-x0)/a ) + y0
      #p_2 = p0 + sc(vec, x_2)
      #p_2.z = p0.z + y_2
      #point_array << p_2
      p_2 = Geom::Point3d.new(x_2, 0, y_2)
      # Intersection of the tangents of the new point and the previous point.
      #x = (p_2.z - p_1.z + slope_1 * p_1.x - slope_2 * p_2.x) / (slope_1 - slope_2)
      #y = slope_1 * (x - p_1.x) + p_1.z
line_1 = [p_1, [1, 0, slope_1]]
line_2 = [p_2, [-1, 0, -slope_2]]
p_ = Geom.intersect_line_line(line_1, line_2)
      p = p0 + sc(vec, p_.x)
      p.z = p0.z + p_.z
      point_array << p
      p_1, slope_1 = p_2, slope_2
    }
=end
  end
  point_array[0] = p0   # First point: use the requested point to avoid discrepancy
  point_array[-1] = p1  # Last point: use the requested point to avoid discrepancy
  return point_array
end


# Scalar product.
def sc(vec, float)
  return Geom::Vector3d.new(vec.x*float, vec.y*float, vec.z*float)
end



class Translate


  def initialize(language_strings, dir=nil)
    @strings = Hash.new;
    locale = Sketchup.get_locale.downcase
    @strings.merge!(language_strings[locale]) if language_strings.include?(locale)
  end


  # Method to access a single translation.
  # @param [String] key  the original string used in the ruby script
  # @param [String] s1 optional string for substitution of %1
  # @param [String] s2 optional string for substitution of %2
  # @returns [String] translated string
  #
  def [](key, s1=nil, s2=nil)
    value = @strings[key]
    return key if value.nil?
    value.gsub!(/\%1/, s1) if !s1.nil?
    value.gsub!(/\%2/, s2) if !s2.nil?
    return value.chomp
  end


end # class Translate



unless file_loaded?(File.basename(__FILE__))
  @@translate = Translate.new(@@language_strings)
  cmd = UI::Command.new(@@translate["Draw Wires"]+" ("+@@translate["Catenary"]+")") {
    Sketchup.active_model.select_tool(AE::WireTool.new)
  }
  cmd.tooltip = @@translate["Tool to draw catenary curves."]
  cmd.small_icon = File.join(@@dir, "icon_wiretool_16.png")
  cmd.large_icon = File.join(@@dir, "icon_wiretool_24.png")
  UI.menu("Plugins").add_item(cmd)
  UI::Toolbar.new(@@translate["Draw Wires"]).add_item(cmd)
end



end # class WireTool



end # module AE



file_loaded(File.basename(__FILE__))
