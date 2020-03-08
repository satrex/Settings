#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Dec. 2007 by Fredo6
#Credit to Carlos António dos Santos Falé (carlosfale@sapo.pt) for the algorithm of Cubic Bezier
#  published in March 2005 as macro cubicbezier.rb

# This software is provided as an example of using the Ruby interface to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name		:   BZ__CubicBezier.rb
# Type		:   A plugin extension to bezierspline.rb. Cannot be used in standalone
# Description	:   Cubic Bezier spline curve are drawn with a set of control points which are located on the curve.
# Menu Item	:   Draw Cubic Bezier Spline
# Context Menu	:   Edit Cubic Bezier Spline Curve
# Usage		:   See Tutorial  on 'Bezierspline.rb'
# Date		:   10 Dec 2007
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

BZ__CUBICBEZIER__LIST = "BZ__CubicBezier"

module BZ__CubicBezier


BZ_TYPENAME = "BZ__CubicBezier"
BZ_MENUNAME = ["Cubic Bezier curve", 
               "|FR|Courbe de Bezier spline cubique",
			   "|DE|kubische Bezierkurve",
			   "|HU|Harmadfokú Bezier görbe",
			   "|ES|Curva Bezier Cúbica",
			   "|PT|Curva de Bezier spline cúbica"]
BZ_PRECISION_MIN = 1
BZ_PRECISION_MAX = 20
BZ_PRECISION_DEFAULT = 7
BZ_CONTROL_MIN = 3
BZ_CONTROL_MAX = 200
BZ_CONTROL_DEFAULT = 999
BZ_CONVERT = "BZ__Polyline"
BZ_LOOPMODE = -2		#allow closing by segment and by Bezier curve

	
# the main function respecting the bezierspline callback interface
def BZ__CubicBezier.bz_compute_curve(pts, precision)
	BZ__CubicBezier.curve pts, precision
end

# Calculation function to compute the Cubic Bezier curve
# receive a array of points (array of three values, x, y and z) and the number of segments
# to interpolate betwen each two points of the array of points

def BZ__CubicBezier.prepare_points(points)
	pt1 = points[0]
	pt2 = points[1]
	vec = pt2.vector_to pt1
	d = pt1.distance pt2
	ptbeg = pt1.offset vec, d
	
	pt1 = points[-1]
	pt2 = points[-2]
	vec = pt2.vector_to pt1
	vec = points[-3].vector_to pt1 unless vec.valid?	
	d = pt1.distance pt2
	ptend = pt1.offset vec, d
	
	[ptbeg] + points + [ptend]
end

def BZ__CubicBezier.curve(points, nt)
  points = BZ__CubicBezier.prepare_points points
  curve = []
  nseg = points.length - 1

  aux_cpoints = find_cpoints(points)
  aux_pointscpoints = join_pointscpoints(points, aux_cpoints)

  for ind in (0..nseg - 1)
    aux_p0 = aux_pointscpoints[3 * ind]
    aux_p1 = aux_pointscpoints[3 * ind + 1]
    aux_p2 = aux_pointscpoints[3 * ind + 2]
    aux_p3 = aux_pointscpoints[3 * ind + 3]
    aux_abc = BZ__CubicBezier.calculate_coef_abc(aux_p0, aux_p1, aux_p2, aux_p3)
    aux_segment = BZ__CubicBezier.segment(aux_p0, aux_abc, nt)
    aux_segment.pop
    curve = curve + aux_segment
  end

  curve.push(aux_pointscpoints[3 * nseg])

  return curve[nt..-(nt+1)]

end


# given a nt integer (number of segments to interpolate) interpolate nt points of a segment
def BZ__CubicBezier.segment(p0, abc, nt)

  segment = []

  for ind in (0..nt)
    segment[ind] = BZ__CubicBezier.point(p0, abc, ind/nt.to_f)
  end

  return segment

end


# given a point, the abc coeficients and a 0<=t<=1, interpolate a point using the cubic formula
def BZ__CubicBezier.point(p0, abc, t)

  bezier_point = []
  bezier_point = [abc[0][0] * t * t * t + abc[1][0] * t * t + abc[2][0] * t + p0[0], abc[0][1] * t * t * t + abc[1][1] * t * t + abc[2][1] * t + p0[1], abc[0][2] * t * t * t + abc[1][2] * t * t + abc[2][2] * t + p0[2]]

  return bezier_point

end


# calculate the abc coeficients of four points for the cubic formula
def BZ__CubicBezier.calculate_coef_abc(p0, p1, p2, p3)

  aux_a = []
  aux_b = []
  aux_c = []
  coef_abc = []

  aux_c = [3 * (p1[0] - p0[0]), 3 * (p1[1] - p0[1]), 3 * (p1[2] - p0[2])]
  aux_b = [3 * (p2[0] - p1[0]) - aux_c[0], 3 * (p2[1] - p1[1]) - aux_c[1], 3 * (p2[2] - p1[2]) - aux_c[2]]
  aux_a = [p3[0] - p0[0] - aux_c[0] - aux_b[0], p3[1] - p0[1] - aux_c[1] - aux_b[1], p3[2] - p0[2] - aux_c[2] - aux_b[2]]

  coef_abc = [aux_a, aux_b, aux_c]

  return coef_abc

end


# find the cpoints vector of a main points vector
def BZ__CubicBezier.find_cpoints(points)

  cpoints = []
  aux_a = []
  aux_b = []
  np = points.length - 1

  cpoints[0] = [(points[1][0] - points[0][0]) / 3, (points[1][1] - points[0][1]) / 3, (points[1][2] - points[0][2]) / 3]
  cpoints[np] = [(points[np][0] - points[np - 1][0]) / 3, (points[np][1] - points[np - 1][1]) / 3, (points[np][2] - points[np - 1][2]) / 3]
                          
  aux_b[1] = -0.25
  aux_a[1] = [(points[2][0] - points[0][0] - cpoints[0][0]) / 4, (points[2][1] - points[0][1] - cpoints[0][1]) / 4, (points[2][2] - points[0][2] - cpoints[0][2]) / 4]

  for ind in (2..np - 1)
    aux_b[ind] = -1 / (4 + aux_b[ind - 1])
    aux_a[ind] = [-(points[ind + 1][0] - points[ind - 1][0] - aux_a[ind - 1][0]) * aux_b[ind], -(points[ind + 1][1] - points[ind - 1][1] - aux_a[ind - 1][1]) * aux_b[ind], -(points[ind + 1][2] - points[ind - 1][2] - aux_a[ind - 1][2]) * aux_b[ind]]
  end

  for ind in (1..np - 1)
    cpoints[np - ind] = [aux_a[np - ind][0] + aux_b[np - ind] * cpoints[np - ind + 1][0], aux_a[np - ind][1] + aux_b[np - ind] * cpoints[np - ind + 1][1], aux_a[np - ind][2] + aux_b[np - ind] * cpoints[np - ind + 1][2]]
  end

  return cpoints

end


# join two vectors, main points vector and cpoints vector
def BZ__CubicBezier.join_pointscpoints(points, cpoints)

  pointscpoints = []
  np = points.length - 1

  for ind in (0..np - 1)
    pointscpoints.push(points[ind])
    pointscpoints.push([points[ind][0] + cpoints[ind][0], points[ind][1] + cpoints[ind][1], points[ind][2] + cpoints[ind][2]])
    pointscpoints.push([points[ind + 1][0] - cpoints[ind + 1][0], points[ind + 1][1] - cpoints[ind + 1][1], points[ind + 1][2] - cpoints[ind + 1][2]])
  end

  pointscpoints.push(points[np])

  return pointscpoints

end

end #End module BZ__CubicBezier