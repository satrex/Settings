#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Dec. 2007 by Fredo6
#Credit to David F. Rogers S - 'An Introduction to NURBS - an historical perspective' (2000) for the algorithm of B-Spline, 
#I simply adapted the original code in C to Ruby

# This software is provided as an example of using the Ruby interface to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name		:   BZ__Catmull.rb
# Type		:   A plugin extension to bezierspline.rb. Cannot be used in standalone
# Description	:   Uniform B-spline curve (i.e. drawn with a set of control points which are located on the curve),
#			     with control of the total number of segments
# Menu Item	:   Draw Uniform B-Spline
# Context Menu	:   Edit Uniform B-Spline Curve
# Usage		:   See Tutorial  on 'Bezierspline.rb' for general information on cerating / editing the curve
# Date		:   10 Dec 2007
# Credit		:  Stephen Carmody
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

BZ__CATMULL__LIST = "BZ__Catmull"

module BZ__Catmull

BZ_TYPENAME = "BZ__Catmull"
BZ_MENUNAME = ["Catmull Spline", 
               "|FR|Spline de Catmull",
			   "|ES|Spline de Catmull"]
BZ_PRECISION_MIN = 2
BZ_PRECISION_MAX = 30
BZ_PRECISION_DEFAULT = 7
BZ_CONTROL_MIN = 3
BZ_CONTROL_MAX = 200
BZ_CONTROL_DEFAULT = 999
#BZ_CONVERT = "BZ__Polyline, Bezier, BZ__CubicBezier"
BZ_CONVERT = "*"
BZ_LOOPMODE = 2			#allow closing by segment and by Bezier curve
BZ_VERTEX_MARK = 1		#show vertex marks by default


	
# the main function respecting the bezierspline callback interface
def BZ__Catmull.bz_compute_curve(pts, precision, loop)
	BZ__Catmull.curve pts, precision, loop
end

#-------------------------------------------------------------------------------------------------------------
# Private methods doing the calculation
#-------------------------------------------------------------------------------------------------------------

# Add a point at each extremity, to handle first and last point
def BZ__Catmull.adjust_points(pts)
	ptfirst = pts[0].offset pts[0].vector_to(pts[1]).reverse
	ptlast = pts[-1].offset pts[-2].vector_to(pts[-1])	
	[ptfirst] + pts + [ptlast]
end

# Calculation function to compute the Catmull Spline
# receive a array of points (array of three values, x, y and z) and the number of segments
def BZ__Catmull.curve(pts, numseg, loop)
	#Adding points at extremities, unless we close the loop
	pts = BZ__Catmull.adjust_points pts unless loop == 2
	
	#computing the Catmull spline by portion
	curve = []
	nbpts = pts.length - 4
	dt = 1.0 / (numseg - 1)
	BZ__Catmull.portion curve, pts[-1], pts[0], pts[1], pts[2], numseg, dt if loop == 2
	for i in 0..nbpts
		BZ__Catmull.portion curve, pts[i], pts[i+1], pts[i+2], pts[i+3], numseg, dt
	end	

	# Closing the loop via a segment or a portion of Catmull spline
	if loop == 1
		curve.push pts[1]
	elsif loop == 2
		BZ__Catmull.portion curve, pts[-3], pts[-2], pts[-1], pts[0], numseg, dt
		BZ__Catmull.portion curve, pts[-2], pts[-1], pts[0], pts[1], numseg, dt
	end
	
    return curve
end

#Compute a portion of the Catmull spline
def BZ__Catmull.portion (curve, p1, p2, p3, p4, numseg, dt)
	for i in 0..numseg-1
		t = i * dt
		pt = Geom::Point3d.new
		pt.x = BZ__Catmull.interpolate p1.x, p2.x, p3.x, p4.x, t		
		pt.y = BZ__Catmull.interpolate p1.y, p2.y, p3.y, p4.y, t		
		pt.z = BZ__Catmull.interpolate p1.z, p2.z, p3.z, p4.z, t	
		curve.push pt
	end
end

# Calculate the coordinates of a point interpolated at <t>
def BZ__Catmull.interpolate(a1, a2, a3, a4, t)
	(a1 * ((-t + 2) * t - 1) * t + a2 * (((3 * t - 5) * t) * t + 2) +
     a3 * ((-3 * t + 4) * t + 1) * t + a4 * ((t - 1) * t * t)) * 0.5
end

end #End module BZ__Catmull