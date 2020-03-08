#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Dec. 2007 by Fredo6
# Credit to David F. Rogers S - 'An Introduction to NURBS - an historical perspective' (2000) for the algorithm of B-Spline, 
# I simply adapted the original code in C to Ruby

# This software is provided as an example of using the Ruby interface to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name		:   BZ__FSpline.rb
# Type		:   A plugin extension to bezierspline.rb. Cannot be used in standalone
# Description	:   Uniform B-spline curve (i.e. drawn with a set of control points which are located on the curve),
#			     with control of the total number of segments
# Menu Item	:   Draw Uniform B-Spline fitted to a polyline
# Context Menu	:   Edit Fit Spline
# Usage		:   See Tutorial  on 'Bezierspline.rb' for general information on cerating / editing the curve
# Date		:   7 Oct 2008
# Sources		:  Wikipedia for Matrix inversion (modified and adapted)
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

BZ__FSPLINE__LIST = "BZ__FSpline"

module BZ__FSpline


BZ_TYPENAME = "BZ__FSpline"
BZ_MENUNAME = ["F-Spline", 
               "|FR|F-Spline",
			   "|ES|F-Spline"]
BZ_PRECISION_MIN = 7
BZ_PRECISION_MAX = 400
BZ_PRECISION_DEFAULT = 30
BZ_CONTROL_MIN = 3
BZ_CONTROL_MAX = 200
BZ_CONTROL_DEFAULT = 999
BZ_CONVERT = "BZ__Polyline, Bezier, BZ__CubicBezier"
BZ_LOOPMODE = -15				#allow closing by segment and by Bezier curve
BZ_VERTEX_MARK = 1				#show vertex marks by default

TTH_Title = ["Parameters of F-Spline ",
             "|FR| Paramètres de F-Spline",
			 "|ES| Parámetros de F-Spline"]

	
# the main function respecting the bezierspline callback interface
def BZ__FSpline.bz_compute_curve(pts, precision, loop)
	BZ__FSpline.curve pts, precision
end

#-------------------------------------------------------------------------------------------------------------
# Private top-level methods doing the calculation
#-------------------------------------------------------------------------------------------------------------

def BZ__FSpline.curve(pts_orig, precision)	
	#Computing the bissector for each original control points
	order = 3
	order = pts_orig.length if order > pts_orig.length
	nbpts = pts_orig.length - 2
	vplane = []
	result = []
	pts = [pts_orig.first]
	for i in 1..nbpts
		vec1 = pts_orig[i].vector_to(pts_orig[i-1]).normalize
		break if (pts_orig[i] == pts_orig[i+1])
		vec2 = pts_orig[i].vector_to(pts_orig[i+1]).normalize
		vbis = vec1 + vec2
		normal = (vbis.valid?) ? vbis * (vec1 * vec2) : vec1
		vplane[i] = [pts_orig[i], normal]
		pts[i] = pts_orig[i]
	end
	
	#Iteration on moving control points
	pts += [pts_orig.last]
	factor = 1.5
	
	curve = BZ__FSpline.compute_bspline pts_orig, precision, order
	for iter in 0..2
		ptinter = BZ__FSpline.compute_intersect pts_orig, curve, vplane
		next unless ptinter.length > 0
		for i in 1..nbpts
			d = pts_orig[i].distance ptinter[i]
			vec = ptinter[i].vector_to pts_orig[i]
			pts[i] = pts[i].offset vec, d * factor if vec.valid?
		end	
		curve = BZ__FSpline.compute_bspline pts, precision, order
		
	end	
	return curve
end

def BZ__FSpline.compute_intersect(pts, curve, vplane)
	nbpts = pts.length - 2
	nbcurve = curve.length - 2
	ptinter = [curve[0]]
	jbeg = 0
	for i in 1..nbpts
		for j in jbeg..nbcurve
			begin
				pt = BZ__FSpline.intersect_segment_plane(curve[j], curve[j+1], vplane[i])
			rescue
				break
			end	
			if pt
				ptinter[i] = pt
				jbeg = j
				break
			end
		end
	end	
	ptinter += [curve.last]
	return ptinter
end

def BZ__FSpline.intersect_segment_plane(pt1, pt2, plane)
	pt = Geom.intersect_line_plane [pt1, pt2], plane
	return nil unless pt
	return pt if (pt == pt1) || (pt == pt2)
	vec1 = pt1.vector_to pt
	vec2 = pt2.vector_to pt
	(vec1 % vec2 <= 0) ? pt : nil
end
#===========================================================================
# COMPUTE A UNIFORM B-SPLINE GIVEN THE CONTROL POINTS
#===========================================================================

# Calculation function to compute the Cubic Bezier curve
# receive a array of points (array of three values, x, y and z) and the number of segments
# to interpolate betwen each two points of the array of points
def BZ__FSpline.compute_bspline(pts, numseg, order)
	#initialization
	curve = []
	nbpts = pts.length
	kmax = nbpts + order - 1
	
	#Generating the uniform open knot vector
	knot = []
	knot[0] = 0.0
	for i in 1..kmax
		knot[i] = ((i >= order) && (i < nbpts + 1)) ? knot[i-1] + 1.0 : knot[i-1]
	end
	
	#calculate the points of the B-Spline curve
	t = 0.0
	step = knot[kmax] / numseg
	for icrv in 0..numseg	
		#calculate parameter t
		t = knot[kmax] if (knot[kmax] - t) < 0.0000001
		
		#calculate the basis
		basis = BZ__FSpline.bspline_basis order, t, nbpts, knot
		
		#Loop on the control points
		pt = Geom::Point3d.new
		pt.x = pt.y = pt.z = 0.0
		for i in 0..(nbpts-1)
			pt.x += basis[i] * pts[i].x
			pt.y += basis[i] * pts[i].y
			pt.z += basis[i] * pts[i].z
		end
		curve.push pt
		t += step
	end
 
    return curve
end


# given a nt integer (number of segments to interpolate) interpolate nt points of a segment
def BZ__FSpline.bspline_basis(order, t, nbpts, knot)
    basis = []
	kmax = nbpts + order - 1

    for i in 0..(kmax-1)
		basis [i] = (t >= knot[i] && t < knot[i+1]) ? 1.0 : 0.0
    end
	
	for k in 1..(order-1)
		for i in 0..(kmax-k-1)
			d = (basis[i] == 0.0) ? 0 : ((t - knot[i]) * basis [i]) / (knot[i+k] - knot[i])
			e = (basis[i+1] == 0.0) ? 0 : ((knot[i+k+1] - t) * basis[i+1]) / (knot[i+k+1] - knot[i+1])
			basis[i] = d + e
		end
	end
	basis [nbpts-1] = 1.0 if t == knot[kmax]

    return basis
end

end #End module BZ__FSpline
