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
# Name		:   BZ__Segmentor.rb
# Type		:   A plugin extension to bezierspline.rb. Cannot be used in standalone
# Description	:   Divide a polyline in a specified number of segments
# Menu Item	:   Polyline Segmentor
# Context Menu	:   Edit Polyline Segmentor
# Usage		:   See Tutorial on 'Bezierspline extensions'
# Date		:   22 Mar 2008
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

#require 'Traductor.rb'

BZ__SEGMENTOR__LIST = ["BZ__Segmentor"]



module BZ__Segmentor

BZ_TYPENAME = "BZ__Segmentor"			#symbolic name - DO NOT TRANSLATE
BZ_MENUNAME = ["Polyline Segmentor", "|FR| Segmenteur de Polyline", "|ES| Segmentador de Polilínea"]
BZ_CONTROL_MIN = 2			#Compute method shhould be called as of second point and just a segment is valid
BZ_CONTROL_MAX = 200
BZ_CONTROL_DEFAULT = 999	#open-ended mode
BZ_PRECISION_MIN = 1		#precision parameter not meaningful
BZ_PRECISION_MAX = 1
BZ_LOOPMODE = 1		#allow closing by segment only, managed by the present module
BZ_VERTEX_MARK = 1	#show vertex marks by default
BZ_CONVERT = "*"	#convert any curve made of at least 2 segments

MAX_POINTS = 500

TTH_Title = ["Parameters of Polyline Segmentor",
             "|FR| Paramètres du Segmenteur de Polyline",
			 "|ES| Parámetros de Segmentador de Polilínea"]
TTH_NBSeg = ["Number of segments", "|FR| Nombre de segments", "|ES| Nº de segmentos"]

#-------------------------------------------------------------------------------------------------------------
# Callback methods implementing the bezierspline required interface
#-------------------------------------------------------------------------------------------------------------

def BZ__Segmentor.bz_compute_curve(pts, numseg, loop, extras)
	for j in 0..20
		pts = BZ__Segmentor.calculate pts, loop, extras
		d0 = pts[-3].distance pts[-2]
		d1 = pts[-2].distance pts[-1]
		break if (d0 - d1).abs / d0 < 0.00001
	end	
	pts
end

def BZ__Segmentor.bz_ask_extras (mode, extras, pts, precision)
	
	# Designing the dialog box
	unless @dlg
		@def_extras = {}
		@dlg = Traductor::DialogBox.new TTH_Title
		@dlg.field_numeric "NBSeg", TTH_NBSeg, 5, 2, nil
	end		
	
	# We store the last value in Creation or Conversion mode, to be reused at next Creation or Conversion
	hsh = @dlg.show((mode != 'E') ? @def_extras : extras)
	@def_extras.replace hsh if (hsh && mode != 'E')
	return hsh	
end

#-------------------------------------------------------------------------------------------------------------
# Private methods doing the calculation
#-------------------------------------------------------------------------------------------------------------
	
def BZ__Segmentor.calculate(pts, loop, extras)	
	#we compute the curve with a possible closure, as we need to divide the closure as well
	pts = pts + pts[0..0] if (loop != 0)
	
	#getting the Interval and checking it - If 0, then there is no point to do the calculation
	nbseg = extras["NBSeg"]
	return pts if (nbseg < 1)
	#preserve = true
	
	#computing the total length of the polygon of control points - if too high, then refuse calculation
	leng = 0.cm
	nbpt = pts.length-1
	for i in 0..nbpt-1
		leng += pts[i].distance pts[i+1]
	end	
	#nbseg = leng / interval
	interval = leng / nbseg
	if (nbseg > MAX_POINTS)
		unless (@beeping)
			3.times {UI.beep}
			@beeping = true
		end	
		return pts
	else
		@beeping = false
	end
	nbseg = nbseg.to_i
	
	#Loop to compute each new points at equal distance
	# pt is the current vertex, from which we search the intersection at distance 'interval' on segment [pt1, pt2] 
	
	nbpts = pts.length - 1
	crvpts = []
	pt = pt1 = crvpts[0] = pts[0].clone
	pt2 = pts[i2 = 1]
	iloop = 0
	
	while (iloop < MAX_POINTS)
		mu = BZ__Segmentor.intersect_ray_sphere pt1, pt2, pt, interval
		
		if (mu <= 1.0)			# Next vertex is on segment [pt1, pt2]
			pt = Geom.linear_combination 1.0 - mu, pt1, mu, pt2
			crvpts.push pt.clone
		else
			if (i2 >= nbpts)	# We reach the last control point - put it in the curve and return
				crvpts.push pt2.clone
				break				
			end
			pt1 = pt2			#we went beyond the control point- try with next segment
			#crvpts.push pt1.clone if preserve
			pt2 = pts[i2 += 1]
		end
		iloop += 1
	end #while true
	
	#returning the computed curve
	crvpts
end


def BZ__Segmentor.intersect_ray_sphere(p1, p2, sc, r)

#   Calculate the intersection of a ray and a sphere
#   The line segment is defined from p1 to p2
#   The sphere is of radius r and centered at sc
#   There are potentially two points of intersection given by
#   p = p1 + mu1 (p2 - p1)
#   p = p1 + mu2 (p2 - p1)
#   Return FALSE if the ray doesn't intersect the sphere.
#   Credit to Paul Bourke (1992)- see http://local.wasp.uwa.edu.au/~pbourke/geometry/sphereline/

    dp = Geom::Point3d.new 
	tolerance = 0.001.cm
   
    dp.x = p2.x - p1.x
    dp.y = p2.y - p1.y
    dp.z = p2.z - p1.z
   
	a = dp.x * dp.x + dp.y * dp.y + dp.z * dp.z
	b = 2 * (dp.x * (p1.x - sc.x) + dp.y * (p1.y - sc.y) + dp.z * (p1.z - sc.z))
	c = sc.x * sc.x + sc.y * sc.y + sc.z * sc.z
	c += p1.x * p1.x + p1.y * p1.y + p1.z * p1.z
	c -= 2 * (sc.x * p1.x + sc.y * p1.y + sc.z * p1.z)
	c -= r * r
	bb4ac = b * b - 4 * a * c
   
	if (a.abs < tolerance || bb4ac < 0)
		puts "No solution"
		return 99999.9
	end	

    mu1 = (-b + Math.sqrt(bb4ac)) / (2 * a);
    mu2 = (-b - Math.sqrt(bb4ac)) / (2 * a);

	mu1
end

end #End module BZ__Segmentor