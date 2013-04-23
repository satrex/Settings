#------------------------------------------------------------------------------------------------
# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#------------------------------------------------------------------------------------------------
# THIS PLUGIN WAS DEVELOPED AND TESTED UNDER WINDOWS VISTA ONLY AND MAY OR MAY NOT WORK ON A MAC. 
#------------------------------------------------------------------------------------------------
#    Name:	Generate Ceiling Grid IV
#      By:	sdmitch
#   Usage:	Generates a drop ceiling grid from a face.
#		 Note:	I have tried to make the plugin as flexible as possible regarding the shape of the face.
#						Interior columns or walls that create "holes" in the shape are acceptable.
#    Date:	Feb 2012
#------------------------------------------------------------------------------------------------

if !file_loaded?(File.basename(__FILE__))
	UI.menu("Plugins").add_item("Ceiling Grid IV") { SDM_GCGIV.gen_grid }
	file_loaded(File.basename(__FILE__))
end

module SDM_GCGIV
	
	def self.gen_grid
		mod = Sketchup.active_model
		ent = mod.active_entities
		sel = mod.selection
		unless sel.empty? || sel.first.class!=Sketchup::Face
			@tile_size = "2X4" if !@tile_size; @start_pt = "Corner" if !@start_pt; @rotate = "No" if !@rotate
			ans=UI.inputbox([" Tile Size:"," Origin Pt:","Rotate 90:"],[@tile_size,@start_pt,@rotate],["2X2|2X4","Corner|Center","Yes|No"], "Generate Grid")
			if !ans then return end
			@tile_size=ans[0]; @start_pt = ans[1]; @rotate = ans[2]
			mod.start_operation "Ceiling Grid"
			@grp = ent.add_group;@ge = @grp.entities;
			face = sel.first; face.reverse! if face.normal.z > 0.0
			pts=face.outer_loop.vertices.collect{|v| v.position}
			case @tile_size
				when "2X2" : dx = 24.125.inch; dy = 24.125.inch;
				when "2X4" : dx = 48.125.inch; dy = 24.125.inch;
			end
			self.face_to_grid(face,pts,dx,dy)
			### convert boundary edges in to "L" members
			for loop in face.loops
				edges=loop.edges
				edges.each{|e| self.create_cgm(face,e,"E")}
			end
			ent.erase_entities(face)
			mod.commit_operation
		else
			UI.messagebox "Select a face"
		end
	end
	
	def self.face_to_grid(face,pts,dx,dy)
		mod = Sketchup.active_model
		ent = mod.active_entities
		if pts.length > 4
			longest_side = 0.0; #find the longest pair of adjacent sides
			for i in -1...pts.length-1
				dist=pts[i-1].distance(pts[i]) + pts[i].distance(pts[i+1])
				if dist > longest_side
					longest_side = dist; # save longer distance
					ndx = i; # save index of common point
				end
			end
		else
			ndx=1; # assume regular 4 sided rectangle
		end
		d1=pts[ndx].distance(pts[ndx+1]); # length of X side
		d2=pts[ndx].distance(pts[ndx-1]); # length of Y side
		dmax = [dx,dy].max; ndx -= 1 if d2>d1
		if (d1 >= dmax && d2 >= dmax); # make sure the rectangle is big enough to sub-divide
			nx=(face.bounds.diagonal*1.5/dx).ceil;ny=(face.bounds.diagonal*1.5/dy).ceil
			if @rotate == "No"
				v1=pts[ndx].vector_to(pts[ndx+1]); # vector of X side
				v2=pts[ndx].vector_to(pts[ndx-1]); v3 = Geom::Vector3d.new(v1.y,-v1.x,0)
				v2.angle_between(v3) > Math::PI/2 ? v2 = v3.reverse : v2 = v3
			else
				v1=pts[ndx].vector_to(pts[ndx-1]); # vector of X side
				v2=pts[ndx].vector_to(pts[ndx+1]); v3 = Geom::Vector3d.new(v2.y,-v2.x,0)
				v1.angle_between(v3) > Math::PI/2 ? v1 = v3.reverse : v1 = v3
			end
			edges=[]; edges=face.edges;ln1=[pts[ndx],v1];ln2=[pts[ndx],v2]
			data=[]; row=[]; @yaxis = v2; # vector of Y side
			if @start_pt == "Corner"
				pt0 = pts[ndx].offset(v1,-dx*(nx/4)).offset(v2,-dy*(ny/4));#puts "corner pt0=#{pt0}"
			else
				pt0 = face.bounds.center.offset(v1,-dx*(nx/2)).offset(v2,-dy*(ny/2));#puts "center pt0=#{pt0}"
			end
			# Compute all end points
			for i in 0..ny
				row[0] = pt0
				for j in 1..nx
					row[j]=row[j-1].offset(v1,dx)
				end
				data[i]=row; row=[]
				pt0.offset!(v2,dy)
			end
			# Draw the "horizontal" lines
			for i in 1..ny
				start_pt_outside = (face.classify_point(data[i][0]) == Sketchup::Face::PointOutside)
				#ent.add_cpoint(data[i][0]) if start_pt_outside
				for j in 1..nx
					end_pt_outside = (face.classify_point(data[i][j]) == Sketchup::Face::PointOutside)
					#ent.add_cpoint(data[i][j]) if end_pt_outside
					if start_pt_outside && !end_pt_outside
						if [2,4].include?(face.classify_point(data[i][j]))
							pt0 = data[i][j]; #puts "pt0 is on an edge"
						else
							pt0 = self.find_intersection(data[i][j-1],data[i][j],edges)
						end
						start_pt_outside = false;
					elsif end_pt_outside && !start_pt_outside
						pt1 = self.find_intersection(data[i][j-1],data[i][j],edges)
						@rotate == "Yes" ? pt2 = pts[ndx-1] : pt2 = pts[ndx+1]
						if pt1 && (!self.is_between(pt0,pts[ndx],pt2) || !self.is_between(pt1,pts[ndx],pt2))
							edge=@ge.add_line(pt0,pt1)
							self.create_cgm(face,edge,"T")
						end
						start_pt_outside = true;
					elsif !start_pt_outside && !end_pt_outside # start and end both on face, check for holes
						@rotate == "Yes" ? pt2 = pts[ndx-1] : pt2 = pts[ndx+1]
						if (!self.is_between(data[i][j-1],pts[ndx],pt2) || !self.is_between(data[i][j],pts[ndx],pt2))
							ray = [data[i][j-1],v1]; hit = mod.raytest(ray)
							if hit && [1,2,4].include?(face.classify_point(hit[0]))
								if self.is_between(hit[0],data[i][j-1],data[i][j])
									edge = @ge.add_line(pt0,hit[0])
									self.create_cgm(face,edge,"T")
									ray = [hit[0],v1]; hit = mod.raytest(ray)
									if hit && [1,2,4].include?(face.classify_point(hit[0]))
										pt0 = hit[0] if self.is_between(hit[0],data[i][j-1],data[i][j])
									end
								end
							end
						else
							pt0 = data[i][j]; pt0 = pts[ndx+1] if face.classify_point(data[i][j])==1
						end
					elsif start_pt_outside && end_pt_outside # start and end both off the face, check for edge of hole and/or face
						@rotate == "Yes" ? pt2 = pts[ndx-1] : pt2 = pts[ndx+1]
						if (!self.is_between(data[i][j-1],pts[ndx],pt2) || !self.is_between(data[i][j],pts[ndx],pt2))
							ray = [data[i][j-1],v1]; hit = mod.raytest(ray); p0 = nil; p1 = nil
							if hit && [1,2,4].include?(face.classify_point(hit[0]))
								if self.is_between(hit[0],data[i][j-1],data[i][j])
									p0 = hit[0]; ray=[p0,v1]; hit = mod.raytest(ray)
									if hit && [1,2,4].include?(face.classify_point(hit[0]))
										p1 = hit[0] if self.is_between(hit[0],data[i][j-1],data[i][j])
										if p0 and p1
											edge = @ge.add_line(p0,p1)
											self.create_cgm(face,edge,"T")
										end
									end
								end
							end
						end
					end
				end
			end
			# Draw the "vertical" lines
			for j in 1..nx
				for i in 1..ny
					start_pt_outside = (face.classify_point(data[i-1][j]) == Sketchup::Face::PointOutside)
					end_pt_outside = (face.classify_point(data[i][j]) == Sketchup::Face::PointOutside)
					if start_pt_outside && !end_pt_outside
						if ![2,4].include?(face.classify_point(data[i][j]))
							poi=self.find_intersection(data[i-1][j],data[i][j],edges)
							if poi
								edge=@ge.add_line(poi,data[i][j]) if start_pt_outside
								edge=@ge.add_line(data[i-1][j],poi) if end_pt_outside
								self.create_cgm(face,edge,"T")
							end
						end
					elsif !start_pt_outside && end_pt_outside
						if ![2,4].include?(face.classify_point(data[i-1][j]))
							poi=self.find_intersection(data[i-1][j],data[i][j],edges)
							if poi
								edge=@ge.add_line(poi,data[i][j]) if start_pt_outside
								edge=@ge.add_line(data[i-1][j],poi) if end_pt_outside
								self.create_cgm(face,edge,"T")
							end
						end
					elsif !start_pt_outside && !end_pt_outside # start and end both on face, check for holes
						@rotate == "Yes" ? pt2 = pts[ndx+1] : pt2 = pts[ndx-1]
						if (!self.is_between(data[i-1][j],pts[ndx],pt2) || !self.is_between(data[i][j],pts[ndx],pt2))
							ray = [data[i-1][j],v2]; hit = mod.raytest(ray)
							if hit && [1,2,4].include?(face.classify_point(hit[0]))
								if edges.include?(hit[1][0]) && self.is_between(hit[0],data[i-1][j],data[i][j])
									edge = @ge.add_line(data[i-1][j],hit[0])
									self.create_cgm(face,edge,"T")
									ray=[hit[0],v2]; hit = mod.raytest(ray)
									if hit && [1,2,4].include?(face.classify_point(hit[0]))
										if edges.include?(hit[1][0]) && self.is_between(hit[0],data[i-1][j],data[i][j])
											edge = @ge.add_line(hit[0],data[i][j])
											self.create_cgm(face,edge,"T")
										end
									end
								else
									edge = @ge.add_line(data[i-1][j],data[i][j])
									self.create_cgm(face,edge,"T")
								end
							end
						end
					elsif start_pt_outside && end_pt_outside # start and end both off the face, check for edge of hole and/or face
						ray = [data[i-1][j],v2]; hit = mod.raytest(ray); p0 = nil
						if hit && [1,2,4].include?(face.classify_point(hit[0]))
							if edges.include?(hit[1][0]) && self.is_between(hit[0],data[i-1][j],data[i][j])
								p0 = hit[0]; ray=[p0,v2]; hit = mod.raytest(ray)
								if hit && [1,2,4].include?(face.classify_point(hit[0]))
									if edges.include?(hit[1][0]) && self.is_between(hit[0],data[i-1][j],data[i][j])
										if p0
											edge = @ge.add_line(p0,hit[0])
											self.create_cgm(face,edge,"T")
										end
									end
								end
							end
						end
					end
				end
			end
		else
			puts "Max size is greater than short side of rectangle"
		end
	end
	
	def self.create_cgm(face,edge,type)
		mod = Sketchup.active_model
		ent = mod.active_entities
		sel = mod.selection
		pt0 = edge.start.position; pt1 = edge.end.position
		if type == "E" && edge.reversed_in?(face)
			pt0 = edge.end.position; pt1 = edge.start.position
		end
		vec = pt0.vector_to(pt1).normalize; ppd = pt0.distance(pt1)
		unless vec.length==0
			cgm_id = "#{type}X #{ppd}"
			cgm_id = "#{type}Y #{ppd}" if vec.parallel?(@yaxis)
			defs = mod.definitions;cgm = nil
			defs.each{|d| cgm=d if d.name==cgm_id}
			if !cgm
				grp = ent.add_group; ge = grp.entities
				xa,ya,za = Z_AXIS.axes;origin = Geom::Point3d.new
				if type == "T"
					p0 = origin.offset(za,0.5.inch); ppd = -(ppd - 1.0.inch);
					p1 = p0.offset(ya,-0.1250.inch).offset(xa,+0.5000.inch)
					p2 = p1.offset(ya,+0.1250.inch)
					p3 = p2.offset(xa,-0.4375.inch)
					p4 = p3.offset(ya,+1.6250.inch)
					p5 = p4.offset(xa,-0.1250.inch)
					p6 = p5.offset(ya,-1.6250.inch)
					p7 = p6.offset(xa,-0.4375.inch)
					p8 = p7.offset(ya,-0.1250.inch)
					f = ge.add_face(p1,p2,p3,p4,p5,p6,p7,p8)
				elsif type == "E"
					p1 = origin.offset(ya,-0.1250)
					p2 = p1.offset(ya,+1.7500)
					p3 = p2.offset(xa,-0.0625)
					p4 = p3.offset(ya,-1.6250)
					p5 = p4.offset(xa,-0.4375)
					p6 = p5.offset(ya,-0.1250)
					f = ge.add_face(p1,p2,p3,p4,p5,p6)
				end
				f.pushpull -ppd;
				comp = grp.to_component
				comp.definition.name = cgm_id
				cgm = comp.definition
				comp.erase!
			end
			tr = Geom::Transformation.new(pt0,vec)
			@ge.add_instance(cgm,tr)
		end
	end
	
	def self.find_intersection(p0,p1,edges)
		ln0=[p0,p0.vector_to(p1).normalize]
		for e in edges
			ln1=e.line; pp=Geom.intersect_line_line(ln0,ln1)
			if pp && pp != p0
				if self.is_between(pp,e.start.position,e.end.position)
					if self.is_between(pp,p0,p1)
						return pp
					end
				end
			end
		end
		return nil
	end
	
	def  self.is_between(p0,p1,p2)
	# --------------------------------------------------------------------------------
	#	Determine if point p0 is on the line and between end points p1 and p2
	# --------------------------------------------------------------------------------
		line=[p1,p1.vector_to(p2).normalize]
		return false if !p0.on_line? line
		d1=p0.distance p1;d2=p0.distance p2;d3=p1.distance p2 
		return true if d1 <= d3 && d2 <= d3
		return false # p0 is not on line and between p1 and p2
	end
	
end
