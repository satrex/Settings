#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Nov. 2007 by Fredo6
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
# Name		:   BZ__Arc.rb
# Type		:   A plugin extension to bezierspline.rb. Cannot be used in standalone
# Description	:   Draw a polyline with round corners of specified offset.
# Menu Item	:   Polyline Arc
# Context Menu	:   Edit Polyline Arc
# Usage		:   See Tutorial on 'Bezierspline extensions'
# Date		:   2 Apr 2009
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

#require 'Traductor.rb'

BZ__ARC__LIST = ["BZ__Arc"]



module BZ__Arc

BZ_TYPENAME = "BZ__Arc"			#symbolic name - DO NOT TRANSLATE
BZ_MENUNAME = ["Polyline Arc Corners", "|FR| Polyline Angles Ronds", "|ES| Polilínea Esquinas Redondeadas"]
BZ_CONTROL_MIN = 3			#Compute method shhould be called as of third point and just a segment is valid
BZ_CONTROL_MAX = 200
BZ_CONTROL_DEFAULT = 999	#open-ended mode
BZ_PRECISION_MIN = 1		#precision parameter is number of segment of a circle
BZ_PRECISION_MAX = 120
BZ_PRECISION_DEFAULT = 24
BZ_LOOPMODE = 1		#allow closing by segment only, managed by the present module
BZ_VERTEX_MARK = 1	#show vertex marks by default
BZ_CONVERT = "*"	#convert any curve made of at least 2 segments

MAX_POINTS = 500

TTH_Title = ["Parameters of Polyline Arc Corners",
             "|FR| Paramètres du Polyline Angles Ronds",
			 "|ES| Parámetros de Polilínea de Esquinas Redondeadas"]
TTH_Offset = ["Offset", "|FR| Offset", "|ES| Offset"]

#-------------------------------------------------------------------------------------------------------------
# Callback methods implementing the bezierspline required interface
#-------------------------------------------------------------------------------------------------------------

def BZ__Arc.bz_compute_curve(pts, precision, loop, extras)
	BZ__Arc.calculate pts, precision, loop, extras
end

def BZ__Arc.bz_ask_extras (mode, extras, pts, precision)
	
	# Designing the dialog box
	unless @dlg
		@def_extras = {}
		@dlg = Traductor::DialogBox.new TTH_Title
		@dlg.field_numeric "Offset", TTH_Offset, 0.cm, 0.cm, nil
	end		
	
	# We store the last value in Creation or Conversion mode, to be reused at next Creation or Conversion
	hsh = @dlg.show((mode != 'E') ? @def_extras : extras)
	@def_extras.replace hsh if hsh && mode != 'E'
	return hsh	
end

#-------------------------------------------------------------------------------------------------------------
# Private methods doing the calculation
#-------------------------------------------------------------------------------------------------------------
	
def BZ__Arc.calculate(pts, precision, loop, extras)
	#we compute the curve with a possible closure, as we need to divide the closure as well
	return pts if pts.length < 3
	
	#getting the Offset and checking it - If 0, then there is no point to do the calculation
	offset = extras["Offset"]
	return pts if (offset == 0.cm)
	
	#Loop to compute the new curve
	nbpts = pts.length - 3
	crvpts = (loop == 0) ? [pts[0]] : []
	for i in 0..nbpts
		crvpts += BZ__Arc.compute(pts[i], pts[i+1], pts[i+2], offset, precision)
	end
	if loop != 0
		crvpts += BZ__Arc.compute(pts[-2], pts[-1], pts[0], offset, precision)
		crvpts += BZ__Arc.compute(pts[-1], pts[0], pts[1], offset, precision)
		crvpts.push crvpts.first
	else
		crvpts.push pts.last
	end	

	#returning the computed curve
	crvpts
end

#Compute the points for the arc at pt2
def BZ__Arc.compute(pt1, pt2, pt3, offset, precision)
	#cheking the vectors
	vec1 = pt2.vector_to pt1
	vec3 = pt2.vector_to pt3
	return [pt2] if !vec1.valid? || !vec3.valid? || vec1.parallel?(vec3) ||
	                vec1.length < 2 * offset || vec3.length < 2 * offset
	
	#computing the arc cemter and arc extremities on each segment
	ptbeg = pt2.offset vec1, offset
	ptend = pt2.offset vec3, offset
	normal = vec3 * vec1
	vrbeg = vec1 * normal
	vrend = vec3 * normal
	ll = Geom.closest_points [ptbeg, vrbeg], [ptend, vrend]
	return [pt2] unless ll
	ptcenter = ll[0]
	
	#Computing the sectors
	vcbeg = ptcenter.vector_to ptbeg
	vcend = ptcenter.vector_to ptend
	angle = vcbeg.angle_between vcend
	
	nsec = (precision * angle / Math::PI / 2.0).round
	return [pt2] if nsec == 0
	return [ptbeg, ptend] if nsec == 1
	anglesec = angle / nsec
	trot = Geom::Transformation.rotation ptcenter, normal, anglesec
	
	pt = ptbeg
	lpt = [pt]
	for i in 0..nsec-2
		pt = trot * pt
		lpt.push pt
	end
	lpt.push ptend
	
	lpt
end


end #End module BZ__Arc