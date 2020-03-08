#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed July 2008 by Fredo6
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
# Name		:   BZ__Courbette.rb
# Type		:   A plugin extension to bezierspline.rb. Cannot be used in standalone
# Description	:   Join control points by arc of circles (apparently like Spiro in Inkscape and also in Autocad)
# Menu Item	:   Draw Courbette
# Context Menu	:   Edit Courbette
# Usage		:   See Tutorial  on 'Bezierspline.rb'
# Date		:   27 Jul 2008
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

BZ__COURBETTE__LIST = "BZ__Courbette"

module BZ__Courbette


BZ_TYPENAME = "BZ__Courbette"
BZ_MENUNAME = ["Courbette", 
               "|FR|Courbette",
			   "|ES|Courbette"]
BZ_PRECISION_MIN = 0
BZ_PRECISION_MAX = 90
BZ_PRECISION_DEFAULT = 24
BZ_CONTROL_MIN = 3
BZ_CONTROL_MAX = 200
BZ_CONTROL_DEFAULT = 999
BZ_CONVERT = "BZ__Polyline"
BZ_LOOPMODE = -2		#allow closing by segment and by Bezier curve
BZ_VERTEX_MARK = 1	#show vertex marks by default
	
PIXEL_PRECISION = 20
	
# the main function respecting the bezierspline callback interface
def BZ__Courbette.bz_compute_curve(pts, precision)
	BZ__Courbette.curve pts, precision
end

# Calculation function to compute the Cubic Bezier curve
# receive a array of points (array of three values, x, y and z) and the number of segments
# to interpolate betwen each two points of the array of points

def BZ__Courbette.curve(ctrlpts, precision)
	#initialization
	curve = []
	nbctrl = ctrlpts.length
 	
	#precision = 24 if precision == 0
	
	#Precision is just 1 --> just a polyline
	if precision == 1
		ctrlpts.each { |pt| curve.push pt }
		return curve 
	end
 
	#Only one point
	return [ctrlpts.first] if nbctrl == 1
	
	#Only 2 points
	return [ctrlpts.first, ctrlpts.last] if nbctrl == 2 

	#3 points - Computing the first arc, which also determines the plane
	BZ__Courbette.arc_3points(ctrlpts, curve, precision)
  
	#Prolongating the curve
	for i in 3..nbctrl-1
		BZ__Courbette.add_point ctrlpts[i], curve, precision
	end

	#Returning the curve
	return curve
end

#Compute an arc with 3 points
def BZ__Courbette.arc_3points(ctrlpts, curve, precision)
	pt1 = ctrlpts[0]
	pt2 = ctrlpts[1]
	pt3 = ctrlpts[2]
	
	#Check if points are aligned
	if pt2.on_line? [pt1, pt3]
		curve.push pt1, pt2, pt3
		return
	end

	#Computing the arc center		
	vec12 = pt1.vector_to pt2
	vec23 = pt2.vector_to pt3
	normal = vec12 * vec23
	
	vec1 = vec12 * normal
	vec2 = vec23 * normal
	
	ptmid1 = Geom::Point3d.linear_combination 0.5, pt1, 0.5, pt2
	ptmid2 = Geom::Point3d.linear_combination 0.5, pt2, 0.5, pt3
	
	line1 = [ptmid1, vec1]
	line2 = [ptmid2, vec2]
	
	lpt = Geom.closest_points line1, line2
	ptcenter = lpt[0]
	radius = ptcenter.distance pt1
	
	#Sampling value for drawing arc
	vc1 = ptcenter.vector_to pt1
	vc2 = ptcenter.vector_to pt2
	vc3 = ptcenter.vector_to pt3
	angle12 = BZ__Courbette.angle_360 vc1, vc2, normal
	angle13 = BZ__Courbette.angle_360 vc1, vc3, normal
		
	#Computing the arc of circle
	curve.push pt1
	BZ__Courbette.compute_arc curve, ptcenter, radius, normal, pt1, pt2, pt3, precision	
end

#Compute the sampling angle, given the precision, the center and the chord
def BZ__Courbette.sample_step(ptcenter, radius, pt1, pt2, angle_total, precision)
	precision = 24 if precision == 0
	
	#basic calculation
	f = 0.5 * precision * angle_total / Math::PI
	step0 = step = f.to_i + 1
	
	#Correction to avoid too less points
	d12 = pt1.distance pt2	
	darc = 2 * Math::PI * radius / step
	ratio = d12 / darc
	if ratio < 1
		step = (step / ratio).round
		step = step0 if step > step0
	end	
	
	#Correction to avoid too many points
	darc = 2 * Math::PI * radius / step
	view = Sketchup.active_model.active_view
	dref = view.pixels_to_model PIXEL_PRECISION, pt1 
	ratio = dref / darc
	if ratio > 1
		step = (step / ratio).round
		step = step0 if step > step0
	end	
	
	#returning the step value
	step
end

#Compute the points of an arc between 2 points, given the center (pt2 is an optional intermediate point)
def BZ__Courbette.compute_arc(curve, ptcenter, radius, normal, pt1, pt2, pt3, precision)
	#Sampling value for drawing arc
	vc1 = ptcenter.vector_to pt1
	vc3 = ptcenter.vector_to pt3
	angle13 = BZ__Courbette.angle_360 vc1, vc3, normal
	if pt2
		vc2 = ptcenter.vector_to pt2
		angle12 = BZ__Courbette.angle_360 vc1, vc2, normal
	end

	#Computing the step angle and transformation
	step = BZ__Courbette.sample_step ptcenter, radius, pt1, pt3, angle13, precision
	angle = angle13 / step
	t = Geom::Transformation.rotation ptcenter, normal, angle
	
	#Computing the arc by rotating the initial vector
	vc = vc1
	angle_sofar = 0
	for i in 0..step-1
		angle_sofar += angle
		vc = vc.transform t
		pt = ptcenter.offset vc, radius
		if pt2
			prox = BZ__Courbette.insert_constraint angle_sofar, angle12, angle
			case prox
			when 0
				curve.push pt
			when -1
				curve.push pt2
			else
				curve.push pt2 if angle12 < angle_sofar
				curve.push pt
			end	
		else
			curve.push pt
		end	
	end	
	prox = BZ__Courbette.insert_constraint angle_sofar, angle13, angle
	if prox == -1
		curve[-1..-1] = pt3
	else
		curve.push pt3	
	end
end

#Compute an angle between 0 and 360 degrees between 2 vectors
def BZ__Courbette.angle_360(vec1, vec2, normal)
	angle = vec1.angle_between vec2
	angle = 2 * Math::PI - angle if (vec1 * vec2) % normal < 0
	angle
end

#Check how to insert a Ctrl point within the curve
def BZ__Courbette.insert_constraint(angle_sofar, angle_exact, angle_step)
	diff = angle_exact - angle_sofar
	return 0 if diff.abs > angle_step
	return -1 if (diff.abs < angle_step * 0.25)
	return 1
end

#Add a point to the curve
def BZ__Courbette.add_point(pt, curve, precision)
	
	#Last vector and plane
	pt1 = curve[-2]
	pt2 = curve[-1]
	vtangent = pt1.vector_to pt2
	vchord = pt2.vector_to pt
		
	#Checking if points are colinear	
	if (vtangent.normalize % vchord.normalize).abs > 0.999
		curve.push pt
		return
	end
	
	#computing the center of the arc
	normal = vtangent * vchord
	unless normal.valid?
		curve.push pt
		return
	end
		
	vperp1 = vtangent * normal 
	vperp2 = vchord * normal 

	line1 = [pt2, vperp1]
	ptmid = Geom::Point3d.linear_combination 0.5, pt2, 0.5, pt
	line2 = [ptmid, vperp2]
	
	lpt = Geom.closest_points line1, line2
	ptcenter = lpt[0]
	radius = ptcenter.distance pt2
	vc1 = ptcenter.vector_to pt2
	angle13 = 
	angle12 = 0
	
	#Computing the arc
	BZ__Courbette.compute_arc curve, ptcenter, radius, normal, pt2, nil, pt, precision	
end

end #End module BZ__Courbette