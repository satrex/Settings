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
# Name		:   BZ__Animation.rb
# Type		:   A plugin extension to bezierspline.rb. Cannot be used in standalone
# Description	:   Divide a polyline in segments of specified length.
# Menu Item	:   Polyline Animation
# Context Menu	:   Edit Polyline Animation
# Usage		:   See Tutorial on 'Bezierspline extensions'
# Date		:   2 Nov 2007
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

#require 'Traductor.rb'

BZ__ANIMATION__LIST = ["BZ__Animation"]



module BZ__Animation

BZ_TYPENAME = "BZ__Animation"			#symbolic name - DO NOT TRANSLATE
BZ_MENUNAME = ["Polyline Divider for Animation", 
               "|FR| Diviseur de Polyline pour Animation",
			   "|ES| Divisor de Polilínea para Animación"]
BZ_CONTROL_MIN = 2			#Compute method shhould be called as of second point and just a segment is valid
BZ_CONTROL_MAX = 9999
BZ_CONTROL_DEFAULT = 999	#open-ended mode
BZ_PRECISION_MIN = 1		#precision parameter not meaningful
BZ_PRECISION_MAX = 1
BZ_LOOPMODE = 1		#allow closing by segment only, managed by the present module
BZ_VERTEX_MARK = 1	#show vertex marks by default
BZ_CONVERT = "*"	#convert any curve made of at least 2 segments

TTH_Title = ["Parameters of Polyline Animation",
             "|FR| Paramètres du Diviseur de Polyline pour Animation",
			 "|ES| Parámetros de Divisor de Polilínea para Animación"]
			 
TTH_Mode = ["Mode", "|FR| Mode", "|ES|Modo"]
TTH_Min = ["MIN Step length", "|FR| Longueur minimum", "|ES| Longitud Mínima"]
TTH_Max = ["MAX Step length", "|FR| Longueur maximum", "|ES| Longitud Máxima"]

MSG_InvMin = ["Minimum is Zero", "|FR| Minimum égal à Zéro", "|ES| Mínima es Cero"]
MSG_InvMax = ["Maximum is Zero", "|FR| Maximum égal à Zéro", "|ES| Máxima es Cero"]
MSG_MaxMin = ["Min greater than Max", "|FR| Minimum plus grand que Maximum", "|ES| Mínima mayor que Máxima"]

ENU_Mode = { 
            '=-' => ["Equal Step (minimum)", "|FR| Uniforme (Min value)", "|ES| Uniforme (Min valor)"], 
            '=+' => ["Equal Step (maximum)", "|FR| Uniforme (Max value)", "|ES| Uniforme (Max valor)"], 
  			'A' => ["Acceleration Min to Max", "|FR| Acceleration", "|ES| Aceleracion"],			 
			'D' => ["Deceleration Max to Min", "|FR| Deceleration", "|ES| Deceleracion"],			 
			'M' => ["Acceleration then deceleration Min - Max - Min", "|FR| Acceleration puis deceleration Min - Max - Min",
			        "|ES| Aceleracion cuando la deceleracion Min - Max - Min"],			 
			'V' => ["Deceleration then Acceleration Max - Min - Max", "|FR| Deceleration puis Acceleration Max - Min - Max",
			        "|ES| Deceleracion cuando la Aceleracion Man - Min - Max"]			 
     	   }		  


#-------------------------------------------------------------------------------------------------------------
# Callback methods implementing the bezierspline required interface
#-------------------------------------------------------------------------------------------------------------

def BZ__Animation.bz_compute_curve(pts, numseg, loop, extras)
	BZ__Animation.calculate pts, loop, extras
end

def BZ__Animation.bz_ask_extras(mode, extras, pts, precision)
	BZ__Animation.ask_param mode, extras, pts, precision
end

#-------------------------------------------------------------------------------------------------------------
# Private methods doing the calculation
#-------------------------------------------------------------------------------------------------------------
	
#Dialog box to ask the parameters
def BZ__Animation.ask_param(mode, extras, pts, precision)
	
	# Designing the dialog box
	unless @dlg
		@def_extras = {}
		@dlg = Traductor::DialogBox.new TTH_Title
		@dlg.field_enum "Mode", TTH_Mode, '=+', ENU_Mode, ['=-', '=+', 'A', 'D', 'M', 'V']
		@dlg.field_numeric "Xmin", TTH_Min, 0.cm, 0.cm, nil
		@dlg.field_numeric "Xmax", TTH_Max, 0.cm, 0.cm, nil
	end		
	
	# We store the last value in Creation or Conversion mode, to be reused at next Creation or Conversion
	while true
		hsh = @dlg.show((mode != 'E') ? @def_extras : extras)
		@def_extras.replace hsh if hsh && mode != 'E'
		return hsh unless hsh
		
		#Checking the values
		mode = hsh["Mode"]
		xmin = hsh["Xmin"]
		xmax = hsh["Xmax"]
		if xmin == 0 && mode != '=+' 
			UI.messagebox Traductor[MSG_InvMin]
		elsif xmax == 0 && mode != '=-'
			UI.messagebox Traductor[MSG_InvMax]
		elsif xmax < xmin
			UI.messagebox Traductor[MSG_MaxMin]
		else
			break
		end
	end
	
	return hsh	
end

#Calculate the polyine
def BZ__Animation.calculate(pts, loop, extras)
	
	#we compute the curve with a possible closure, as we need to divide the closure as well
	pts = pts + pts[0..0] if (loop != 0)
	
	#getting the Interval and checking it - If 0, then there is no point to do the calculation
	xmin = extras["Xmin"].to_f
	xmax = extras["Xmax"].to_f
	mode = extras["Mode"]
	
	#Computing the series of steps
	lsteps = BZ__Animation.step_sampling pts, mode, xmin, xmax	
	return pts if lsteps.length == 0
	
	#Dividing the polyline
	BZ__Animation.divide(pts, lsteps)
end

#Divide the polyline along the defined steps in <lsteps>
def BZ__Animation.divide(pts, lsteps)
	crvpts = [pts[0]]
	i0 = 0
	js = 0
	step = lsteps[js]
	curpt = pts[0]
	
	while true
		pt1 = pts[i0+1]
		unless pt1 && step
			if crvpts.last.distance(pts.last) < lsteps.last * 0.4
				crvpts[-1..-1] = pts.last
			else	
				crvpts.push pts.last
			end	
			break
		end	
		
		d = curpt.distance pt1
		if d >= step
			curpt = curpt.offset pts[i0].vector_to(pt1), step
			crvpts.push curpt
			js += 1
			i0 += 1 if d == step
			step = lsteps[js]
		else
			curpt = pt1
			step -= d
			i0 += 1
		end	
	
	end
	
	crvpts
end

#Computing the list of steps for the given mode and min / max parameters
def BZ__Animation.step_sampling(pts, mode, xmin, xmax)

	#Computing the total length of the curve
	leng = 0
	nbpt = pts.length - 1
	for i in 0..nbpt-1
		leng += pts[i].distance pts[i+1]
	end	

	#Uniform animation
	lminmax = [xmin, xmax]
	lminmax = lminmax.reverse if mode =~ /[DV\+]/
	lsteps = []
	if (mode =~ /\=/) || xmin == xmax
		#nbseg = (mode == '=+') ? leng / xmax : leng / xmin
		nbseg = leng / lminmax[0]
		nbseg = nbseg.round
		step0 = leng / nbseg
		for i in 0.. nbseg-1
			lsteps[i] = step0
		end	
		
	#Acceleration or Decelration	
	elsif mode == 'A' || mode == 'D'
		accel = ((xmax * xmax - xmin * xmin) / 2.0 / leng)
		nbseg = (xmax - xmin) / accel
		nbseg = nbseg.round
		BZ__Animation.algo leng, nbseg, lsteps, lminmax[0], lminmax[1]

	#Smoothstep	
	else	
		leng = leng * 0.5
		accel = ((xmax * xmax - xmin * xmin) / 2.0 / leng)
		nbseg = (xmax - xmin) / accel
		nbseg = nbseg.round
		BZ__Animation.algo leng, nbseg, lsteps, lminmax[0], lminmax[1]
		BZ__Animation.algo leng, nbseg, lsteps, lminmax[1], lminmax[0]

	end
	
	#BZ__Animation.print(lsteps)
	
	lsteps	
end

#computing the corrections
def BZ__Animation.algo(leng, nbseg, lsteps, step0, step1)
	sumi = nbseg * (nbseg - 1) / 2
	accel = (leng - nbseg * step0) / sumi
	for i in 0..nbseg-1
		a = step0 + accel * i
		lsteps.push a
	end
end

#Print the list of steps
def BZ__Animation.print(lsteps)
	sum = 0
	prev = lsteps.first
	for i in 0..lsteps.length-1
		sum += lsteps[i]
		puts "i = #{i} Step = #{Sketchup.format_length(lsteps[i])} prev = #{Sketchup.format_length(lsteps[i] - prev)}"
		prev = lsteps[i]
	end
	puts "SUM final = #{Sketchup.format_length sum}"
	
	lsteps
end
end #End module BZ__Animation