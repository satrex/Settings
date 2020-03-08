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
# Name		:   BZ__BSplineU.rb
# Type		:   A plugin extension to bezierspline.rb. Cannot be used in standalone
# Description	:   Uniform B-spline curve (i.e. drawn with a set of control points which are located on the curve),
#			     with control of the total number of segments
# Menu Item	:   Draw Uniform B-Spline
# Context Menu	:   Edit Uniform B-Spline Curve
# Usage		:   See Tutorial  on 'Bezierspline.rb' for general information on cerating / editing the curve
# Date		:   10 Dec 2007
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

BZ__BSPLINEU__LIST = "BZ__BSplineU"

module BZ__BSplineU


BZ_TYPENAME = "BZ__BSplineU"
BZ_MENUNAME = ["Uniform B-Spline", 
               "|FR|B-Spline Uniforme",
			   "|DE|gleichmäßige B-Spline",
			   "|HU|Egyenletes B-függvény",
			   "|ES|B-Spline Uniforme",
			   "|PT|B-Spline Uniforme"]
BZ_PRECISION_MIN = 15
BZ_PRECISION_MAX = 400
BZ_PRECISION_DEFAULT = 30
BZ_CONTROL_MIN = 3
BZ_CONTROL_MAX = 200
BZ_CONTROL_DEFAULT = 999
BZ_CONVERT = "BZ__Polyline, Bezier, BZ__CubicBezier"
BZ_LOOPMODE = -15		#allow closing by segment and by Bezier curve
BZ_VERTEX_MARK = 1		#show vertex marks by default

TTH_Title = ["Parameters of Uniform B-Spline ",
             "|FR| Paramètres de B-Spline Uniforme",
			 "|HU| Uniform B-spline paraméterei",
			 "|ES| Parámetros de B-Spline Uniforme",
			 "|PT| Parâmetros de B-Spline Uniforme"]
TTH_Order = ["Order (0 means Automatic)", 
             "|FR| Ordre (0 pour automatique)",
			 "|HU| Sorrend (ha 0, automatikus)",
			 "|PT| Ordem (0 para Máxima"]

	
# the main function respecting the bezierspline callback interface
def BZ__BSplineU.bz_compute_curve(pts, precision, loop, extras)
	order = extras["Order"]
	return pts if (order ==1)
	BZ__BSplineU.curve BZ__BSplineU.adjust_points(pts), precision, order
end

def BZ__BSplineU.bz_ask_extras (mode, extras, pts, precision)
	
	# Designing the dialog box
	unless @dlg
		@def_extras = {}
		@dlg = Traductor::DialogBox.new TTH_Title
		@dlg.field_numeric "Order", TTH_Order, 0, 0, 100
	end		
	
	# We store the last value in Creation or Conversion mode, to be reused at next Creation or Conversion
	hsh = @dlg.show((mode != 'E') ? @def_extras : extras)
	@def_extras.replace hsh if (hsh && mode != 'E')
	return hsh	
end

#-------------------------------------------------------------------------------------------------------------
# Private methods doing the calculation
#-------------------------------------------------------------------------------------------------------------

def BZ__BSplineU.adjust_points(pts)
	[pts.first] + pts + [pts.last]
end

def BZ__BSplineU.oldadjust_points(pts)
	newpts =[]
	newpts[ip = 0] = pts[0].clone
	newpts[ip += 1] = Geom::Point3d.linear_combination 0.5, pts[0], 0.5, pts[1]
	n = pts.length-2
	for i in 1..n
		newpts[ip += 1] = pts[i].clone
	end
	newpts[ip += 1] = Geom::Point3d.linear_combination 0.5, pts[n], 0.5, pts[n+1]
	newpts[ip += 1] = pts[n+1].clone
	newpts	
end

# Calculation function to compute the Cubic Bezier curve
# receive a array of points (array of three values, x, y and z) and the number of segments
# to interpolate betwen each two points of the array of points
def BZ__BSplineU.curve(pts, numseg, order)

	#initialization
	curve = []
	nbpts = pts.length
	order = nbpts if (order > nbpts || order == 0)
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
		basis = BZ__BSplineU.basis order, t, nbpts, knot
		
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
def BZ__BSplineU.basis(order, t, nbpts, knot)

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

end #End module BZ__BSplineU