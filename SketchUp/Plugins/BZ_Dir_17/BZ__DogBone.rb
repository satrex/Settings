#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Dec. 2009 by Fredo6

# This software is provided as an example of using the Ruby interface to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name		:   BZ__DogBone.rb
# Type		:   A plugin extension to bezierspline.rb. Cannot be used in standalone
# Description	:   Equip corners with a Dogbone shape
# Menu Item	:   Polyline DogBone
# Context Menu	:   Edit Dogbone Polyline
# Usage		:   See Tutorial on 'Bezierspline extensions'
# Date		:   22 Dec 2009
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

#require 'Traductor.rb'

BZ__DOGBONE__LIST = ["BZ__DogBone", "BZ__TBone"]



module BZ__DogBone

BZ_TYPENAME = "BZ__DogBone"			#symbolic name - DO NOT TRANSLATE
BZ_MENUNAME = ["Polyline Dog-Bone Corners", "|FR| Polyline Coins Dog-Bone", "|ES| Polilínea de esquinas Huesudas"]
BZ_CONTROL_MIN = 3			#Compute method shhould be called as of third point and just a segment is valid
BZ_CONTROL_MAX = 200
BZ_CONTROL_DEFAULT = 999	#open-ended mode
BZ_PRECISION_MIN = 1		#precision parameter is number of segment of a circle
BZ_PRECISION_MAX = 120
BZ_PRECISION_DEFAULT = 24
BZ_LOOPMODE = 1		#allow closing by segment only, managed by the present module
BZ_VERTEX_MARK = 0	#show vertex marks by default
BZ_CONVERT = "*"	#convert any curve made of at least 2 segments

MAX_POINTS = 500

TTH_Title = ["Parameters of Polyline Dog-Bone  Corners",
             "|FR| Paramètres du Polyline Coins Dog-Bone",
			 "|ES| Parámetros de Polilínea de Esquinas Huesudas"]
TTH_Radius = ["Radius", "|FR| Rayon", "|ES| Radio"]

#-------------------------------------------------------------------------------------------------------------
# Callback methods implementing the bezierspline required interface
#-------------------------------------------------------------------------------------------------------------

def BZ__DogBone.bz_compute_curve(pts, precision, loop, extras)
	BZ__DogBone.calculate pts, precision, loop, extras
end

def BZ__DogBone.bz_ask_extras (mode, extras, pts, precision)
	
	# Designing the dialog box
	unless @dlg
		@def_extras = {}
		@dlg = Traductor::DialogBox.new TTH_Title
		@dlg.field_numeric "Radius", TTH_Radius, 0.cm, 0.cm, nil
	end		
	
	# We store the last value in Creation or Conversion mode, to be reused at next Creation or Conversion
	hsh = @dlg.show((mode != 'E') ? @def_extras : extras)
	@def_extras.replace hsh if (hsh && mode != 'E')
	return hsh	
end

#-------------------------------------------------------------------------------------------------------------
# Private methods doing the calculation
#-------------------------------------------------------------------------------------------------------------
	
def BZ__DogBone.calculate(pts, precision, loop, extras)
	#we compute the curve with a possible closure, as we need to divide the closure as well
	return pts if pts.length < 3
	
	#getting the Radius and checking it - If 0, then there is no point to do the calculation
	radius = extras["Radius"]
	return pts if (radius == 0.cm)
	
	#Loop to compute the new curve
	nbpts = pts.length - 3
	crvpts = (loop == 0) ? [pts[0]] : []
	for i in 0..nbpts
		crvpts += BZ__DogBone.compute(pts[i], pts[i+1], pts[i+2], radius, precision)
	end
	if loop != 0
		crvpts += BZ__DogBone.compute(pts[-2], pts[-1], pts[0], radius, precision)
		crvpts += BZ__DogBone.compute(pts[-1], pts[0], pts[1], radius, precision)
		crvpts.push crvpts.first
	else
		crvpts.push pts.last
	end	

	#returning the computed curve
	crvpts
end

#Compute the points for the arc at pt2
def BZ__DogBone.compute(pt1, pt2, pt3, radius, precision)
	#cheking the vectors
	vec1 = pt2.vector_to pt1
	vec3 = pt2.vector_to pt3
	return [pt2] if !vec1.valid? || !vec3.valid? || vec1.parallel?(vec3)
	
	#Computing the offset
	angle_min = 15.degrees
	angle_corner = vec1.angle_between vec3
	return [pt2] if (angle_corner < angle_min) || (Math::PI - angle_corner) < angle_min
	
	offset = 2 * radius * Math.cos(angle_corner * 0.5)
	return [pt2] if vec1.length < 2 * offset || vec3.length < 2 * offset
	
	#computing the arc cemter and arc extremities on each segment
	ptbeg = pt2.offset vec1, offset
	ptend = pt2.offset vec3, offset
	vmid = Geom.linear_combination 0.5, vec1, 0.5, vec3
	normal = vec3 * vec1
	ptcenter = pt2.offset vmid, radius
	
	#Computing the sectors
	vcbeg = ptcenter.vector_to ptbeg
	vcend = ptcenter.vector_to ptend
	angle = vcbeg.angle_between vcend
	angle = Math::PI * 2 - angle if angle_corner < Math::PI * 0.5
	
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


end #End module BZ__DogBone

#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
# Module T-Bone
#----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------

module BZ__TBone

BZ_TYPENAME = "BZ__TBone"			#symbolic name - DO NOT TRANSLATE
BZ_MENUNAME = ["Polyline T-Bone Corners", "|FR| Polyline Coins T-Bone"]
BZ_CONTROL_MIN = 3			#Compute method shhould be called as of third point and just a segment is valid
BZ_CONTROL_MAX = 200
BZ_CONTROL_DEFAULT = 999	#open-ended mode
BZ_PRECISION_MIN = 1		#precision parameter is number of segment of a circle
BZ_PRECISION_MAX = 120
BZ_PRECISION_DEFAULT = 24
BZ_LOOPMODE = 1		#allow closing by segment only, managed by the present module
BZ_VERTEX_MARK = 0	#show vertex marks by default
BZ_CONVERT = "*"	#convert any curve made of at least 2 segments

MAX_POINTS = 500

TTH_Title = ["Parameters of Polyline T-Bone  Corners",
             "|FR| Paramètres du Polyline Coins T-Bone"]
TTH_Radius = ["Radius", "|FR| Rayon"]

#-------------------------------------------------------------------------------------------------------------
# Callback methods implementing the bezierspline required interface
#-------------------------------------------------------------------------------------------------------------

def BZ__TBone.bz_compute_curve(pts, precision, loop, extras)
	BZ__TBone.calculate pts, precision, loop, extras
end

def BZ__TBone.bz_ask_extras (mode, extras, pts, precision)
	
	# Designing the dialog box
	unless @dlg
		@def_extras = {}
		@dlg = Traductor::DialogBox.new TTH_Title
		@dlg.field_numeric "Radius", TTH_Radius, 0.cm, 0.cm, nil
	end		
	
	# We store the last value in Creation or Conversion mode, to be reused at next Creation or Conversion
	hsh = @dlg.show((mode != 'E') ? @def_extras : extras)
	@def_extras.replace hsh if (hsh && mode != 'E')
	return hsh	
end

#-------------------------------------------------------------------------------------------------------------
# Private methods doing the calculation
#-------------------------------------------------------------------------------------------------------------
	
def BZ__TBone.calculate(pts, precision, loop, extras)
	#We compute the curve with a possible closure, as we need to divide the closure as well
	return pts if pts.length < 3
	
	#Getting the Radius and checking it - If 0, then there is no point to do the calculation
	radius = extras["Radius"]
	return pts if (radius == 0.cm)
	
	#Loop to compute the new curve
	nbpts = pts.length - 3
	crvpts = (loop == 0) ? [pts[0]] : []
	for i in 0..nbpts
		crvpts += BZ__TBone.compute(pts[i], pts[i+1], pts[i+2], radius, precision)
	end
	if loop != 0
		crvpts += BZ__TBone.compute(pts[-2], pts[-1], pts[0], radius, precision)
		crvpts += BZ__TBone.compute(pts[-1], pts[0], pts[1], radius, precision)
		crvpts.push crvpts.first
	else
		crvpts.push pts.last
	end	

	#returning the computed curve
	crvpts
end

#Compute the points for the arc at pt2
def BZ__TBone.compute(pt1, pt2, pt3, radius, precision)
	#cheking the vectors
	vec1 = pt2.vector_to pt1
	vec3 = pt2.vector_to pt3
	return [pt2] if !vec1.valid? || !vec3.valid? || vec1.parallel?(vec3)
	
	#Computing the offset
	angle_min = 15.degrees
	angle_corner = vec1.angle_between vec3
	return [pt2] if (Math::PI - angle_corner) < angle_min
	
	offset = 2 * radius
	return [pt2] if vec1.length < 2 * offset && vec3.length < 2 * offset
	
	#computing the arc cemter and arc extremities on each segment
	ptbeg = pt2.offset vec1, offset
	ptend = pt2.offset vec3, offset
	normal = vec3 * vec1
	
	if pt2.distance(pt1) > pt2.distance(pt3)
		ptend = pt2
	else
		ptbeg = pt2	
	end
	ptcenter = Geom.linear_combination 0.5, ptbeg, 0.5, ptend
		
	#Computing the sectors
	vcbeg = ptcenter.vector_to ptbeg
	vcend = ptcenter.vector_to ptend
	angle = Math::PI
	
	nsec = (precision * 0.5).round
	return [pt2] if nsec <= 1
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


end #End module BZ__TBone