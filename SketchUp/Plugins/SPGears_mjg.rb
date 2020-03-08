# Copyright 2012, by Mark Jason Grundman

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------

# Name        :   SPGears_mjg.rb
# Description :   This file draws various types of gears with involute tooth profiles
# Menu Item   :   Plugins -> SP Gears (MJG)
# Context Menu:   NONE
# Date        :   06/28/2012
# Version     :   1.01
#
#	Doug Herrrman's gear plugin ('gear.3.rb' created in 2006) does a great job of creating
#	a 2D gear profile.  Unfortunately when used to create gears for SketchyPhysics (SP), it did
#	not create accurate collision geometry.  Doug's plug-in inspired (and provided a basis for )
#	this re-work of the concept, which solves many of the collision geomtry problems when used
#	with SP.  However, I need to stress not all problems have been solved.  (If you don't plan to
#	use this with SP, you can skip to the last paragraph.)
#	
#	These gears will work with SP, but they don't work as well as I hoped due to problems within
#	SP.  Any gear created with this tool has fairly complex geometry, from a few hundred to a
#	few thousand entities (faces, edges, etc.), to provide fairly decent accuacy.  That means that
#	complexity increases rapidly as tooth count increases on a single gear.  Add more gears and 
#	complexity jumps exponentially.  Therefore, you can expect SP annimations to run VERY 
#	slow, if at all.  Even when testing with only two gears, each with less than 20-30 teeth, SP
#	would freeze and crash Sketchup.  It may just be my computer, but I don't really know.
#
#	Moving past the SketchyPhysics stuff, this is a really great tool for creating gears in your
#	'static' drawings, too.  I tried to cover as many common gear styles and sizes as possible.
#	It's not yet "finished" (is any code ever finished?), but pretty good for my first attempt 
#	at a plugin.
#
#-----------------------------------------------------------------------------

require 'sketchup.rb'

#=============================================================================

# Generates an Involute Tooth Gear
class SPGear

	# default values for dialog box
	@@teeth = 15
	@@ang_pressure = 20.0  # degrees
	@@rad_pitch = 10.0.inch
	@@face_width = 3.0
	@@ang_helix = 0.0
	@@ang_bevel = 0.0


	def SPGear.dialog
		# First prompt for the dimensions.
		prompts = ["Number of Teeth: ", "Pressure Angle: ", "Pitch Radius/Rack Leng.: ", "Face Width: ", "Helix Angle: ", "Bevel Angle: "]
		values = [@@teeth, @@ang_pressure, @@rad_pitch, @@face_width, @@ang_helix, @@ang_bevel]
			
		# Display the inputbox
		results = inputbox prompts, values, [nil,'14.5|20.0|25.0',nil,nil,nil, nil], "Gear Parameters"
		
		return if not results # This means that the user cancelled the operation
		
		# update default settings
		@@teeth, @@ang_pressure, @@rad_pitch, @@face_width, @@ang_helix, @@ang_bevel = results

		SPGear.new
	end


	def initialize(teeth=@@teeth, ang_pressure=@@ang_pressure, rad_pitch=@@rad_pitch, face_width=@@face_width, ang_helix=@@ang_helix, ang_bevel=@@ang_bevel)
	
		@teeth = teeth.abs
		@ang_pressure = ang_pressure.degrees
		@rad_pitch = rad_pitch.to_f
		@face_width = face_width.to_f
		@ang_helix = ang_helix
		@ang_bevel = ang_bevel.degrees
			
		if ang_bevel != 0
			maxFaceWidth = @rad_pitch / Math.sin(@ang_bevel)
			if @face_width > maxFaceWidth
				@face_width = maxFaceWidth - 0.1
				paramChange = ("Face width parameter exceeded maximum\n" <<
						"  for bevel angle and pitch radius parameters.\n\n" <<
						"Face width was reduced to fit.")
				end
			
			end
		
		#~ rescue ArgumentError => err
			#~ UI.messagebox(err.message)
			#~ Sketchup.undo
		
			#~ end  # rescue block
			

		# calculate various gear attributes, from user input, for later calculations and other uses.
		@pitch_daimeter = 2.0 * @rad_pitch
		@diametral = @pitch_daimeter/@teeth		# number of teeth/inch	   
		@rad_outside = @rad_pitch + @diametral		# + 1/diametral pitch
		@rad_inside = @rad_pitch - @diametral		# - 1/diametral pitch
		@rad_root = @rad_pitch - 1.157*@diametral	# - 1.157/diametral pitch
		@rad_base = @rad_pitch * Math.cos(@ang_pressure)

		# Encapsulate into a single UNDO operation.
		model = Sketchup.active_model
		model.start_operation "Create New Gear(mjg)"

		# set entities as a class variable and add the output group
		entities = model.active_entities
		@mainGroup = entities.add_group
		
		drawSPGear()
		
		model.commit_operation
			
	end  # SPGear.new

	private

	def drawSPGear	
		ptsTooth = []
		
		# create arrays to hold points for a mesh of the base cylinder/cone,
		@ptsBase = []		# points to copy for base mesh
		baseProfile = []	# all base mesh points
			
		# set starting points of involute (tooth profile)
		ang = 0.0
		x0 = @rad_root
		ptsTooth.push([x0,0,0])
		
		# calc value of parameter where Involute curve intersects outside radius
		s_max = Math.sqrt(@rad_outside * @rad_outside - @rad_base * @rad_base)
		ang_max = s_max / @rad_base

		# calc Involute curve points along tooth's right side
		ang += 9.degrees
		while ang < ang_max
			x, y = SPGearInvolute(ang)
			if x < @rad_root
				ptsTooth[0] = [x, y, 0]
				else
					ptsTooth.push([x, y, 0])
				end
			ang += 9.degrees
		end

		#Compute last point where involute intersects the outside circle
		x, y = SPGearInvolute(ang_max)
		ptsTooth.push([x, y, 0])

		# calculate rotation of profiles
		s = Math.sqrt(@rad_pitch**2 - @rad_base**2)
		delta = (s / @rad_base) - @ang_pressure
		
		# rotate so that involute intersects the x-axis at the Pitch radius
		t0 = Geom::Transformation.rotation [0,0,0], Z_AXIS, -delta
		ptsTooth.collect!{|pnt| t0 * pnt}
		
		# Reflect profiles about the x-axis
		t1 = Geom::Transformation.rotation [0,0,0], X_AXIS, 180.degrees
		ptsReflect = ptsTooth.collect{|pnt| t1 * pnt}
		
		# rotate relection one tooth space
		t2 = Geom::Transformation.rotation [0,0,0], Z_AXIS, 180.degrees/@teeth
		ptsReflect.collect!{|pnt| t2 * pnt}
		
		# re-order reflected points and add to profile
		ptsProfile = ptsTooth + ptsReflect.reverse!
		
		# center tooth profile along the X-axis and create initial tooth group
		t3 = Geom::Transformation.rotation [0,0,0], Z_AXIS, -180.degrees/(2*@teeth)
		ptsProfile.collect!{|pnt| t3 * pnt }
		grpTooth = AddSPGearTooth(ptsProfile)
		
		
#  -- NOTE: The SkectchyPhysics plugin/extension overrides the SU API 'group.copy' method.
#  -- Using components as work-around greatly increases drawing speed and enables 
#  -- 'copying' groups without interference from SketchyPhysics
		
		# --- validation to be added...
			# if work-around == exception
				# if SP exists == false
					# try using 'group.copy' method
				#else
					# throw exception and notify user of problem
				# end
			# end
		
		
		# copy tooth group and base points around the root circle --
		#     phase 1: save initial tooth component definition for copies, then explode component as first tooth group
		compTooth = grpTooth.to_component
		compTooth.set_attribute("SPOBJ","shape","convexhull")
		compDef = compTooth.definition
		compTooth.make_unique
		compTooth.explode
	
		# copy- phase 2:  create new tooth (component instance) from definition, rotate to final position, then explode component back to a group
		1.upto(@teeth) do |n|
			t4 = Geom::Transformation.rotation [0,0,0], Z_AXIS, (360.degrees * n / @teeth)
			newTooth = @mainGroup.entities.add_instance(compDef, t4)
			newTooth.set_attribute("SPOBJ","shape","convexhull")
			newTooth.make_unique
			newTooth.explode
			
			# copy- phse 3:  create a copy of original base points, rotated to the same position, within the base profile
			@ptsBase.each{|e|
				copyPts = e.collect{|pnt| t4 * pnt}
				baseProfile.push(copyPts)
				}
			end  # loop to create the next copy (phase 2)

		# generate base cylinder group
		grpBase = AddSPGearBase(baseProfile)
		grpBase.set_attribute("SPOBJ","shape","convexhull")
	
	end  # drawSPGear	
	
	def AddSPGearTooth(pointsArray)
		tempGroup = @mainGroup.entities.add_group
		group = tempGroup.entities.add_group
		group.name="tooth"
		group.set_attribute("SPOBJ","shape","convexhull")
		ent = group.entities
		
		pt1 = pointsArray.size / 2 - 1
		pt2 = pointsArray.size / 2
		pt3 = pointsArray.size - 1
		
		# generate tooth surfaces and collect points for creating end-faces
		endPointsA = ExtrudeSPGearProfile(pointsArray[0..pt1], group, "Face1")
		endPointsB = ExtrudeSPGearProfile(pointsArray[pt1..pt2], group, "TopLand")
		endPointsC = ExtrudeSPGearProfile(pointsArray[pt2..pt3], group, "Face2")
						
		# add faces for end surfaces
		endFace1 = ent.add_face(endPointsA[0] + endPointsC[0])
		endFace1.edges[1].soft = "true"
		endFace2 = ent.add_face(endPointsA[1] + endPointsC[1])
		endFace2.edges[-1].soft="true"
		
		tempGroup   # return complete tooth as a group		
		
	end  #back to drawSPGear

	
	# create a face mesh for each 'face' of the tooth or base (i.e. extrude the curve along a path)
	def ExtrudeSPGearProfile(pointsArray, groupObj, shapeName)
		entities = groupObj.entities
		subGroup = entities.add_group
		ent = subGroup.entities
		
		if @ang_bevel != 0
			t2 = Geom::Transformation.rotation [@rad_pitch,0,0], Y_AXIS, -@ang_bevel
			pts = pointsArray.collect{|pnt| t2 * pnt}
			else
				pts = pointsArray
			end
		
		# grab start point from Face1 and the end point from Face2, for the base cylinder mesh
		ptsBase = []
		ptsBase.push(pts.first) if shapeName == "Face1"
		ptsBase.push(pts.last) if shapeName == "Face2"

		#  add the first cross section (starting curve/edge)
		ptsProfile = []
		ptsProfile.push(pts)
		
		#count once for last cross section (ending curve/edge) and add additional sections for helical
		sectionCnt = 1.0
		if @ang_helix != 0
			# add sections to curve teeth around base mesh
			sectionCnt += (@ang_helix.abs/15.0).ceil
		
			# add sections for larger axial widths (reduce axial distortion)
			sectionCnt += (@face_width.abs/@rad_pitch.abs).floor
		 	
			# add sections for conical helix (minimize radial distortion)
			sectionCnt += (@ang_bevel.abs/17).floor
			
			# calc rotation angle and direction for helical sections
			arcLength = Math.sin(@ang_helix.degrees) * @face_width
			centerAngle = arcLength / @rad_pitch
			arcSection = centerAngle / sectionCnt
		end
		
		sectionWidth = @face_width / sectionCnt
		
		# calc bevel/helical transforms (create path for extrusion mesh)
		1.upto(sectionCnt){|sect|
			#default cross section thickness
			z0 = sectionWidth * sect
			t0 = Geom::Transformation.new [0,0,z0]
	
			if @ang_bevel != 0
				maxConeDistance = @rad_pitch / Math.sin(@ang_bevel)
				scaleFactor = 1 - ((sectionWidth * sect) / maxConeDistance)
					if scaleFactor <= 0.001
						s0 = 0.002
						else
							s0 = scaleFactor
						end
						
				# section thickness decreases as bevel flattens toward 90 degrees from z-axis 
				x0 = @rad_pitch - (@rad_pitch * s0)
				z0 = x0 / Math.sin(@ang_bevel)
				t0 = Geom::Transformation.translation [0,0,z0]
				t1 = Geom::Transformation.scaling [@rad_pitch,0,0], s0, s0, 1
				t2 = Geom::Transformation.rotation [@rad_pitch,0,0], Y_AXIS, -@ang_bevel
				
				if @ang_helix != 0
					t3 = Geom::Transformation.rotation [0,0,0], Z_AXIS, arcSection * sect
					tr = t3 * t2 * t1 * t0
				else
					tr = t2 * t1 * t0
				end
					
			elsif @ang_helix != 0
				t3 = Geom::Transformation.rotation [0,0,0], Z_AXIS, arcSection * sect
				tr = t3 * t0
			else
				tr = t0
			end
			
			# apply transformation to section and grab second base mesh point
			pts = pointsArray.collect{|pnt| tr * pnt}
			ptsBase.push(pts.first) if shapeName == "Face1"
			ptsBase.push(pts.last) if shapeName == "Face2"
			ptsProfile.push(pts)
		
		}  # loop to next cross section
		
		# add surface faces (create extrusion surface from mesh)
		0.upto(sectionCnt - 1){|sect|
			newFaces = []
			sectionPts = pointsArray.size
			0.upto(sectionPts - 2){|pnt| 
				pnt2 = pnt + 1
				sect2 = sect +1
				pt0 = ptsProfile[sect][pnt]
				pt1 = ptsProfile[sect2][pnt]
				pt2 = ptsProfile[sect2][pnt2]
				pt3 = ptsProfile[sect][pnt2]
				
				newFaces[0] = ent.add_face(pt3, pt1, pt0)
				newFaces[1] = ent.add_face(pt3, pt2, pt1)
				#smooth all edges except surface boundries
				newFaces.each{|face|
					face.edges.each{|e|
						sides = e.faces.size
						if sides == 2
							e.smooth="true"
							e.soft="true"
						end
						}
					}
			}
		}
			
		# save accumulated base points
		@ptsBase.push(ptsBase) if (shapeName == "Face1") || (shapeName == "Face2")
			
		# explode extrusion inside of parent group
		subGroup.explode
		
		# collect points to for tooth end-surfaces
		ptsReturn = []
		ptsReturn[0] = ptsProfile.first
		ptsReturn[1] = ptsProfile.last

		ptsReturn   # return end-surface points

	end  # back to AddSPGearTooth


	def AddSPGearBase(pointsArray)
		group = @mainGroup.entities.add_group
		group.name="base"
		ent = group.entities
		ent.add_cline([0,0,0], [0,0,@face_width])
		
		# add points to close the base cirle
		pointsArray.push(pointsArray.first)
		
		sectionCnt = pointsArray[0].size
		pointsCnt = pointsArray.size
		# for all except the last section...
		0.upto(sectionCnt - 2 ){|sect|
			# for all except the last point in a section...
			0.upto(pointsCnt - 2){|pnt|
				pnt2 = pnt +1
				sect2 = sect +1
				
				pts0 = pointsArray[pnt][sect]
				pts1 = pointsArray[pnt][sect2]
				pts2 = pointsArray[pnt2][sect2]
				pts3 = pointsArray[pnt2][sect]
								
				newFaces = []
				#~ # check for, and delete, any duplicate points
				#~ dup = pts.uniq
				
				# if more than 1 point is deleted, skip to the next set of points,...
				#~ if (dup != nil && dup.size < 3)
					#~ next
				#~ else
				#  ... otherwise create a triangluar face from remaining points...
					#~ newFace = ent.add_face(dup[2], dup[1], dup[0])
				#    ... then smooth and soften edges between any adjacent faces
					#~ newFace.edges.each{|edge|
						#~ if edge.faces.size == 2
							#~ e.smooth="true"
							#~ e.soft="true"
							#~ end
						#~ }
					#~ next
				#~ end

				# if no points are deleted, create two triangular faces (divided parallogram)...
				newFaces.push(ent.add_face(pts3, pts1, pts0))
				newFaces.push(ent.add_face(pts3, pts2, pts1))
				
				# ... then smooth and soften edges between any adjacent faces
				newFaces.each{|face|
					face.edges.each{|edge|
						if edge.faces.size == 2
							edge.smooth="true"
							edge.soft="true"
							end
						}
					}
			}
		}

		# collect end-face points from first and last sections
		sections = [0, (pointsArray[0].size-1)]
		sections.each{|sect|
			endPoints = []
			pointsArray.each{|pnt|
				endPoints.push(pnt[sect])
				}

			# create end-faces from each set of points...
			newCurve = ent.add_curve(endPoints)
			newFace = ent.add_face(newCurve)

			# ... and soften edges of end-faces adjacent to teeth			
			allEdges = newFace.edges.size - 1
			0.step(allEdges, 2){|e|
				newFace.edges[e].soft = "true"
				}
			}
		
		group   # return complete base cylinder as a group
		
	end  # back to DrawSPGear
	
	
	def LogToFile(obj)
		currTime = Time.now().to_i
		fileName = "log_file_" << currTime.to_s << ".txt"
		Dir::chdir("C:/Users/Jason/Downloads/Sketchup Plugins")
		logFile = File.new(fileName, "w")
		if File.exists?(logFile)
			logFile.syswrite(obj.to_s)
			UI.messagebox("Log file created.\n" << Dir::pwd << fileName)		
			else
				UI.messagebox("failed to create dump file")
			end
			
		logFile = nil
	end
	
		
	# points on involute curve parameterized by ang (in radians)
	def SPGearInvolute(ang)
		x1 = @rad_base * Math.cos(ang)
		y1 = @rad_base * Math.sin(ang)
		s = ang * @rad_base
		x = x1 + s * Math.sin(ang)
		y = y1 - s * Math.cos(ang)
		
		# return x, y coordinates
		[x, y]
		
	end  # back to DrawSPGear
	
end  # class SPGear


#=============================================================================
# User Interface Stuff
if( not file_loaded?("SPGears_mjg.rb") )

	menuPlugins = UI.menu("Plugins")
	menuPlugins.add_separator
	item = menuPlugins.add_item("SPGears_mjg") { SPGear.dialog }
end


#-----------------------------------------------------------------------------
file_loaded("SPGears_mjg.rb")