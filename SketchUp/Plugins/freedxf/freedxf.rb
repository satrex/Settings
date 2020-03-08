=begin

Version:  $Id$

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

=end
#set_trace_func proc { |event, file, line, id, binding, classname| puts "%8s %s:%-2d %10s %8s\n" % [event, file, line, id, classname]}
#require 'dxf2ruby.rb'
load File.dirname(__FILE__) + '/inputbox.rb'
load File.dirname(__FILE__) + "/dxf2ruby.rb"

module JF
    module FreeDXF
        #module_function

        def self.reset
            # reset Inputbox
            @ib = nil
        end

        def self.do_options
            if @ib.nil?
                @ib = Inputbox.new("FreeDXF Options", {:use_keys=>true})
                @ib.add "Arc Segments", 12
                @ib.add "Circle Segments", 24
                @ib.add "Layers", ["Dxf Layers", "Layer0", "by Dxf Type"]
                @ib.add "Import Text?", ["Yes", "No"]
                @ib.add "Screen Text?", ["Yes", "No"], "No"
                @ib.add "Import MText?", ["Yes", "No"]
                @ib.add "Dims?", ["Yes", "No"]
                if $JFDEBUG
                    @ib.add "Debug Tags?", ["No", "Yes"]
                end
            end
            opts = @ib.show
            return opts if opts == false
            @opts = {}
            @opts[:arc_segments]    = 12
            @opts[:circle_segments] = 24
            @opts[:arc_segments]    = opts[0]
            @opts[:circle_segments] = opts[1]
            @opts[:layers]          = opts[2]
            @opts[:text]            = opts[3] == "Yes"
            @opts[:screen_text]     = opts[4] == "Yes"
            @opts[:mtext]           = opts[5] == "Yes"
            @opts[:dims]            = opts[6] == "Yes"
            @opts[:font_quality] = 1.0 # 0.0 is best
            if $JFDEBUG
                @opts[:tags] = (opts[7] == "Yes" ? true : false)
            end
            puts "Options: #{ @opts.inspect }" if $JFDEBUG
        end

        def self.main
            puts "\nFreeDXF debugging ON." if $JFDEBUG
            dir = File.dirname(__FILE__)
            r = UI.openpanel "DXF", "", "*.dxf"
            return if r.nil?
            r.tr!('\\', '/')
            puts "File: #{r.inspect}" if $JFDEBUG
            Sketchup.status_text = "Parsing #{File.basename(r)}"
            dxf = Dxf2Ruby.parse(r)
            return if(do_options == false)
            #dxf.parse

            @layer_entities = {}
            @top_group       = Sketchup.active_model.entities.add_group
            @top_group.name  = File.basename(r)
            @parent_entities = Sketchup.active_model
            @top_entities    = @top_group.entities

            @entities      = @top_entities
            @scale         = 1.0
            @known_types   = Hash.new{0}
            @unknown_types = Hash.new{0}
            @verts         = []


            start_time = Time.now
            Sketchup.active_model.start_operation("FreeDXF", true)
            # Show Some HEADER Info
            acad_ver = dxf['HEADER']['$ACADVER']
            puts "Acad Version: #{acad_ver}" if $JFDEBUG

            if dxf['HEADER']['$MEASUREMENT']
                @dxf_units = dxf['HEADER']['$MEASUREMENT'][70] == 0 ? "English" : "Metric"
            end
            puts "\nUnits: #{@dxf_units}" if $JFDEBUG

            puts "Drawing BLOCKS" if $JFDEBUG

            for b in dxf['BLOCKS']
                if b[0] == "BLOCK"
                    name = b[2].nil? ? b[5] : b[2]
                    uniq_name = Sketchup.active_model.definitions.unique_name(name)
                    d = Sketchup.active_model.definitions.add(uniq_name)
                    @entities = d.entities
                    @in_block = true
                    #set_layer(b)
                elsif b[0] == "ENDBLK"
                    @in_block = false
                    @entities = @top_entities
                else
                    draw(b)
                end
            end

            puts "Drawing ENTITIES" if $JFDEBUG

            len = dxf['ENTITIES'].length
            i = 0
            for e in dxf['ENTITIES']
                #if $JFDEBUG
                #    puts "#{i} / #{len}"
                #    i += 1
                #end
                draw(e)
            end

            #set_layer :layer0
            Sketchup.active_model.active_layer = Sketchup.active_model.layers[0]
            Sketchup.active_model.commit_operation
            if $JFDEBUG
                UI.beep
                puts "Knowns: #{ (@known_types.keys - @unknown_types.keys).join(" ") }"
                puts "Unknowns: #{  @unknown_types.keys.join(" ") }"  
                puts "Time: #{ Time.now - start_time }"
                puts "=" * 79
            end
            dxf = nil
        end

        def self.summary_dialog(sum)
            p sum
            #sum.each_pair { |k, v|
            #puts "#{k}: #{v}"
            #}
        end

        def self.draw(e)
            return unless e.fetch(67, 0) == 0
            @known_types[ e[0] ] += 1
            #set_layer(e)
            case e[0]
            when "POINT"
                draw_point(e)
            when "LINE"
                draw_line(e)
            when "CIRCLE"
                draw_circle(e)
            when "LWPOLYLINE"
                draw_lwpolyline(e)
            when "ARC"
                draw_arc(e)
            when "POLYLINE"
                draw_polyline(e)
            when "SEQEND"
                draw_seqend(e)
            when "VERTEX"
                draw_vertex(e)
            when "SOLID"
                draw_solid(e)
            when "INSERT"
                draw_insert(e)
            when "3DFACE"
                draw_3dface(e)
            when "ELLIPSE"
                draw_ellipse(e)
            when "SPLINE"
                draw_spline(e)
            when "TEXT"
                draw_text(e) if @opts[:text]
            when "MTEXT"
                draw_mtext(e) if @opts[:mtext]
            when "DIMENSION"
                draw_dimension(e) if @opts[:dims]
            else
                @unknown_types[e[0]] += 1
            end
        end

        def self.draw_polyline(e)
            #set_layer :fdxf_polyline
            if e[0] == "POLYLINE"
                @polyline = e
                @verts.clear
                @closed = ((e.fetch(70, 0) & 1) == 1)
                @in_polyline = true
                @handle = e[5]
                #set_layer(e)
                #p e if $JFDEBUG
            end
        end

        def self.draw_seqend(e)
            return unless @in_polyline
            #p e if $JFDEBUG
            #set_layer(@polyline)
            #puts "@verts:#{@verts.inspect}" if $JFDEBUG
            entities = get_entities(@polyline[8])
            @in_polyline = false
            if @verts.length > 0
                @verts.push(@verts[0]) if @closed
                @closed = nil
                lp = nil
                for i in 0..@verts.length-1
                    #puts "vert[#{i}]=#{ @verts[i].inspect }" if $JFDEBUG
                    pos = @verts[i][0]
                    #pos = Geom::Point3d.new(e[10], e[20], e.fetch(30, 0.0))
                    #@entities.add_cpoint(pos)
                    if not lp.nil?
                        b = lp[1] || 0.0
                        if b != 0.0
                            c, radius, x, l = calc_bulge(lp[0], pos, b)
                            #@entities.add_cpoint(c)
                            curve = arc = entities.add_arc(c, x, Z_AXIS, radius, 0, l, @opts[:arc_segments])
                            #@entities.add_text(r['fdxf_id'], c)
                            if curve.nil? and $JFDEBUG
                                warn "no arc (b): #{@handle}"
                            end
                        else
                            curve = entities.add_edges(lp[0], pos)
                            if curve.nil? and $JFDEBUG
                                warn "no arc: #{__LINE__} #{@handle} #{lp[0].inspect}, #{pos.inspect}"
                            end
                        end
                    end
                    lp = @verts[i]#.clone
                end
                if @opts[:tags]
                    curve.each {|c| c.set_attribute("FreeDXF", "handle", @handle.to_s)} rescue nil
                end
                @verts = []
                @data = []
                @seq = nil
            end

        end

        def self.draw_vertex(e)
            if @in_polyline
                pos = Geom::Point3d.new(e[10], e[20], e.fetch(30, 0.0))
                @verts << [pos, e[42] ]
            end
        end

        def self.draw_line(r)
            #if @opts[:layers] == "by Type"
            #set_layer(:fdxf_line)
            #end
            entities = get_entities(r[8])
            pt1 = Geom::Point3d.new(r[10], r[20], r.fetch(30, 0.0))#].map{|e| @scale * e}
            pt2 = Geom::Point3d.new(r[11], r[21], r.fetch(31, 0.0))#].map{|e| @scale * e}
            extrusion = Geom::Vector3d.new(r[210] || 0, r[220] || 0, r[230] || 1)
            extrusion.length = r[39] || 0
            if extrusion.length == 0
                line = entities.add_line(pt1, pt2)
                if line and @opts[:tags]
                    line.set_attribute("FreeDXF", "handle", r[5])
                end
            else
                pt3 = pt2.offset(extrusion)
                pt4 = pt1.offset(extrusion)
                #line = @entities.add_line(pt3, pt4)
                face = entities.add_face(pt1, pt2, pt3, pt4)
                if face and @opts[:tags]
                    face.set_attribute("FreeDXF", "handle", r[5])
                end
            end

            #if $JFDEBUG
            #t = @entities.add_text(r['fdxf_id'], pt1)
            #t.layer = @fdxf_layers[:id]
            #end
        end

        def self.draw_lwpolyline(r)
            #set_layer :fdxf_lwpolyline
            entities = get_entities(r[8])
            pline_flag = r[70]
            nverts = r[90]
            xs = r[10]#.split(@list_sep)
            ys = r[20]#.split(@list_sep)
            bs = r[42]
            lp = nil
            id = r[5]
            if ((pline_flag & 1) == 1)
                xs.push(xs[0])
                ys.push(ys[0])
            end
            if xs.class == Array
                for i in 0..xs.length-2
                    pt = Geom::Point3d.new(xs[i], ys[i])
                    #@entities.add_text(i.to_s, pt)
                    #@entities.add_cpoint(pt)
                    np = Geom::Point3d.new(xs[i+1], ys[i+1])
                    b = bs[i] || 0.0#if bs 
                    if b == 0.0
                        arc = entities.add_line(pt, np)
                    else
                        c, radius, x, l = calc_bulge(pt, np, b)
                        #@entities.add_text("#{i}:#{id}", c)
                        arc = entities.add_arc(c, x, Z_AXIS, radius, 0, l, @opts[:arc_segments])
                        #@entities.add_line(pt, np)
                        #arc.map{|edge| edge.layer = @fdxf_layers[:lwpoly]}
                    end
                    if arc and @opts[:tags]
                        #arc.each{|e| e.set_attribute("FreeDXF", "handle", r[5])}
                    end
                    #end # AND draw cords
                end
            else
                raise "shouldn't be here"
            end
        end

        def self.calc_bulge(p1, p2, bulge)
            cord = p2.vector_to(p1) # vector from p1 to p2
            clength = cord.length
            s = (bulge * clength)/2.0 # sagitta (height)
            radius = (((clength/2.0)**2 + s**2)/(2.0*s)).abs # magic formula
            angle = (4.0 * Math::atan(bulge)).radians #.degrees # theta (included angle)
            radial = cord.clone.normalize # * radius # a radius length vector aligned with cord
            radial.length = radius
            delta = (180.0 - (angle.abs))/2.0 # the angle from cord to center
            delta = -delta if bulge < 0
            rmat = Geom::Transformation.rotation(p1, Z_AXIS, -delta.degrees)
            radial2 = radial.clone
            radial.transform! rmat
            center = p2.offset radial
            #startpoint = p1 - center
            endpoint = p2 - center
            [center, radius, center.vector_to(p1),  angle.degrees]
        end

        def self.draw_circle(r)
            #set_layer :fdxf_circle
            entities = get_entities(r[8])
            center = [r[10], r[20], r.fetch(30, 0.0)].map{|e| @scale * e}
            radius = r[40] * @scale
            #normal = r[210].map{|e| e} if r[210]
            normal = [0, 0, 1] #|| r["210"]
            circle = entities.add_circle(center, normal, radius, @opts[:circle_segments])
            warn "no circle." if circle.nil?
            if circle and @opts[:tags]
                circle.map{|e| e.set_attribute("FreeDXF", "handle", r[5])}
            end

            if @opts[:circle_cpoints]
                cpoint = entities.add_cpoint(center)
                #cpoint.layer = @layer
            end
            #circle.each{|e| e.layer = @layer } if circle
        end

        def self.draw_arc(r)
            #set_layer :fdxf_arc
            #puts r[210] if r[210]
            entities = get_entities(r[8])
            center = Geom::Point3d.new( r[10], r[20], r.fetch(30, 0.0) )# ].map {|e| @scale * e}
            radius = r[40] * @scale
            start_angle = (r[50]+ 360.0).degrees
            end_angle = (r[51]+ 360.0).degrees
            if start_angle > end_angle or end_angle == 0
                end_angle = (end_angle + 360.degrees)#.degrees
            end
            arclen = (end_angle - start_angle).abs
            xaxis = Geom::Vector3d.new(Math.cos(start_angle), Math.sin(start_angle), 0)
            start_angle = 0
            end_angle = arclen
            if end_angle < 0
                start_angle, end_angle = end_angle, start_angle
                start_angle *= -1
            end
            arc = entities.add_arc(center, xaxis, [0, 0, 1], radius, start_angle, end_angle, @opts[:arc_segments])
            if arc.nil?
                warn "draw_arc: no arc."
                cpoint =  entities.add_cpoint(center) if $JFDEBUG
            end
            if $JFDEBUG
                #text =  @entities.add_text(r['fdxf_id'], center)
                #text.layer = @fdxf_layers[:id]
                #cpoint.layer = @layer
            end
        end

        def self.draw_solid(r)
            #set_layer :fdxf_solid
            entities = get_entities(r[8])
            p1 = [ r[10], r[20], r.fetch(30, 0.0)]
            p2 = [ r[11], r[21], r.fetch(31, 0.0)]
            p3 = [ r[12], r[22], r.fetch(32, 0.0)]
            p4 = [ r[13], r[23], r.fetch(33, 0.0)]
            pts = [p1, p2, p3, p4].uniq
            #pts.each_with_index{|pt, i| @entities.add_text(i.to_s, pt)}
            thickness = r.fetch(39, 0)
            # TODO: It's more complex than this...
            dir = [ r[210] || 0, r[220] ||0 , r[230] || 1]
            tr = Geom::Transformation.new(ORIGIN, dir)
            pts = pts.map{|pt| pt.transform!(tr)}
            begin
                #face = @entities.add_face(pts[0], pts[1], pts[3], pts[2])
                face = entities.add_face(pts)#[0], pts[1], pts[3], pts[2])
            rescue
                p pts
                pts.each_with_index {|pt, i| entities.add_cpoint(pt); entities.add_text(i.to_s, pt)}
                #face = @entities.add_face(pts[0], pts[1], pts[3])
                #face = @entities.add_face(pts[1], pts[3], pts[2])
            end
            #face2 = @entities.add_face(pts[1], pts[3], pts[4])
            if face
                face.set_attribute("FreeDXF", "handle", r[5]) if @opts[:tags]
                face.pushpull(-thickness) if thickness != 0
            end
        end

        def self.draw_insert(r)
            #set_layer :fdxf_blocks
            #return if r['ents'].nil?
            pt = Geom::Point3d.new( r[10], r[20], r.fetch(30, 0.0))# ].map{|e| @scale * e}
            xscale = r.fetch(41, 1.0)
            yscale = r.fetch(42, 1.0)
            zscale = r.fetch(43, 1.0)
            angle  = r.fetch(50, 0.0)
            t = Geom::Transformation.new(pt)
            name = r.fetch(2, nil)
            cdef = Sketchup.active_model.definitions[name] if name
            if cdef
                ins = @entities.add_instance(cdef, t)
                t = Geom::Transformation.scaling(pt, xscale, yscale, zscale)
                ins.transform!(t)
                t =Geom::Transformation.rotation(pt, t.zaxis, angle.degrees)
                ins.transform!(t)
                ins.layer = get_layer(r[8])
            end
        end

        def self.draw_3dface(r)
            #set_layer :fdxf_3dface
            entities = get_entities(r[8])
            pt1 = [ r[10], r[20], r.fetch(30, 0.0) ]#.map {|e| @scale * e}
            pt2 = [ r[11], r[21], r.fetch(31, 0.0) ]#.map {|e| @scale * e}
            pt3 = [ r[12], r[22], r.fetch(32, 0.0) ]#.map {|e| @scale * e}
            pt4 = [ r[13], r[23], r.fetch(33, 0.0) ]#.map {|e| @scale * e}
            pts = [pt1, pt2, pt3, pt4]
            begin
                entities.add_face(pts)
            rescue => e
                #@entities.add_face(pt1, pt2, pt3)
                #@entities.add_face(pt1, pt3, pt4)
                pts.each {|pt| entities.add_cpoint(pt)}
            end
        end

        def self.draw_ellipse(r)
            entities = get_entities(r[8])
            #5=>"C59"
            #10=>0.000431 #20=>0.0
            #11=>6.492626953125 #21=>0.0001722547743056 #31=>0.0
            #330=>"C58"
            #0=>"ELLIPSE"
            #100=>["AcDbEntity", "AcDbEllipse"]
            #40=>0.259233
            #62=>7
            #41=>0.0
            #42=>6.28318530717959
            #30=>0.0
            #8=>"LAYER_1"
            #210=>0.0
            #220=>0.0
            #230=>1.0
            #p r if $JFDEBUG
            # 10, 20, 30 - centerpoint
            # 11, 21, 31 - endpoint of major axis relative to the center in WCS
            # 40 - ratio of minor to major axes
            # 41 - start param - 0.0 for a full ellipse
            # 42 - End param - 2pi for full ellipse
            c = [r[10], r[20], r.fetch(30, 0.0)] # .map{|e| @scale * e}
            c = Geom::Point3d.new(c)
            #@entities.add_cpoint(c)
            #@entities.add_text("center", c)
            #end_pt = Geom::Point3d.new([r[11], r[21], r.fetch(31, 0.0)])
            #@entities.add_cpoint(end_pt)
            #@entities.add_text("end_pt", end_pt)
            u1 = r[41]
            u2 = r[42]
            a = [r[11], r[21], r[31]] # .map{|e| @scale * e}
            a = Geom::Point3d.new(a)
            ratio = r[40]
            #w = a.distance(c) / 4.0
            w = a.distance([0,0,0])# / 2.0
            h = w * ratio.to_f
            lpt = nil
            s = ((u2 - u1) / 24.0)
            pts = []
            (u1..u2).step(s) { |u| 
                pt = []
                pt.x = (c.x + w * Math.cos(u))
                pt.y = (c.y + h * Math.sin(u))
                pt.z = 0
                pts << pt.clone
            }
            cp = entities.add_curve(pts)
        end


        def self.draw_point(r)
            #set_layer :fdxf_point
            entities = get_entities(r[8])
            pt = Geom::Point3d.new(r[10], r[20], r.fetch(30, 0.0))
            entities.add_cpoint(pt)
            thick = r.fetch(39, 0.0)
            if thick != 0
                dir = Geom::Vector3d.new(r.fetch(210, 0.0), r.fetch(220, 0.0), r.fetch(230, 1.0))
                dir.length = thick
                pt2 = pt.offset(dir)
                entities.add_line(pt, pt2)
            end
        end # def self.draw_point

        def self.draw_spline(e)
            entities = get_entities(e[8])
            last_pos = nil
            if e[10].respond_to?(:each)
                for i in 0..e[10].length
                    pos = Geom::Point3d.new([ e[10][i] || 0, e[20][i] || 0, e[30][i] || 0 ] )
                    unless last_pos.nil?
                        if pos != ORIGIN
                            entities.add_line(last_pos, pos)
                        end
                    end
                    last_pos = pos.clone
                end
            end
        end
        # {5=>"40D5E", 330=>"18", 0=>"TEXT", 1=>"2'-0\"", 100=>["AcDbEntity", "AcDbText", "AcDbText"], 7=>"ARCHD", 40=>6.0, 62=>0, 30=>0.0, 8=>"TEXT", 20=>1276.87402748742, 10=>670.551253338073}
        # {5=>"40D5A", 330=>"18", 0=>"TEXT", 50=>90.0, 1=>"TO TOP OF O'HANG", 100=>["AcDbEntity", "AcDbText", "AcDbText"], 7=>"ARCHD", 40=>6.0, 62=>0, 30=>0.0, 8=>"TEXT", 20=>1427.03893761635, 10=>63.3665941452673}
        # 

        def self.draw_text(e)
            p e if $JFDEBUG
            entities = get_entities(e[8])
            pt = Geom::Point3d.new([e[10], e[20], e.fetch(30, 0.0)])
            txt = e[1]
            txt.gsub!('\P', "\n")
            txt.gsub!('\~', " ")
            if @opts[:screen_text]
                @entities.add_text(txt, pt)
                return
            end
            unless txt.empty?
                puts "txt: #{ txt.inspect }" if $JFDEBUG
                begin
                    gr = entities.add_group
                    gr.name = "TEXT"
                    gr.material = "Black"
                    gr.set_attribute("FreeDXF", "text", txt)
                    gr.entities.add_3d_text(txt, TextAlignLeft, "Arial", false, false, e[40], 10)
                    gr.transform!(pt)
                    v = text_align_vector(gr, e[71])
                    gr.transform!(v)
                    rot = Geom::Transformation.rotation(gr.transformation.origin, [0, 0, 1], (e[50]||0).degrees)
                    gr.transform!(rot)
                    #gr.explode
                rescue => ex
                    p ex
                    puts ex.backtrace
                    fail
                end
            end
        end

        def self.fix_text(txt)
        end

        def self.draw_mtext(e)
            p e if $JFDEBUG
            pt = Geom::Point3d.new([e[10], e[20], e.fetch(30, 0.0)])
            entities = get_entities(e[8])
            txt = e[1]#.strip
            return if txt.empty?
            # Text as screen text option?
            # @entities.add_text(txt, pt)
            if txt[0].chr == "{" and txt[-1].chr == "}"
                #txt.slice(1, -1)
                txt = txt[1..-2]
            end
            txt.gsub!('\P', "\n")
            txt.gsub!('\~', " ")
            if @opts[:screen_text]
                @entities.add_text(txt, pt)
                return
            end
            bold = false
            italic = false
            if txt[";"]
                codes, txt = txt.split(";")
                codes = codes.split("|")
                p codes if $JFDEBUG
                p txt if $JFDEBUG
                font_code, font = codes[0].split('\f')
                p font if $JFDEBUG
                #bold = codes[1] == "b1"
                #italic = codes[2] == "i1"
                codes.each do |code|
                    italic = true if code == "i1"
                    bold   = true if code == "b1"
                end
            end
            font == font || e[7]
            puts if $JFDEBUG
            return if txt.nil?


            puts "mtxt: #{ txt.inspect }" if $JFDEBUG
            unless txt.strip.empty?
                begin
                    gr = @entities.add_group
                    gr.name = "MTEXT"
                    gr.material = "Black"
                    gr.entities.add_3d_text(txt, TextAlignLeft, "Arial", bold, italic, e[40], @opts[:font_quality])
                    gr.transform!(pt)
                    #Attachment point:
                    #1 = Top left; 2 = Top center; 3 = Top right;
                    #4 = Middle left; 5 = Middle center; 6 = Middle right;
                    #7 = Bottom left; 8 = Bottom center; 9 = Bottom right
                    v = text_align_vector(gr, e[71])
                    gr.transform!(v)
                    rot = Geom::Transformation.rotation(gr.transformation.origin, [0, 0, 1], (e[50]||0).degrees)
                    gr.transform!(rot)
                rescue => ex
                    p ex
                    puts ex.backtrace
                    fail
                end
            end
        end

        def self.text_align_vector(gr, attach_point)
            bb = gr.bounds
            w = gr.bounds.width
            h = gr.bounds.height
            o = gr.transformation.origin
            v = [0, 0,0]
            case attach_point
            when 1; v = [0     , -h]
            when 2; v = [-w/2.0, -h]
            when 3; v = [-w    , -h]
            when 4; v = [0     , -h/2.0]
            when 5; v = [-w/2.0, -h/2.0]
            when 6; v = [-w    , -h/2.0]
            when 7; v = [0     , 0]
            when 8; v = [-w/2.0, 0]
            when 9; v = [-w    , 0]
            end
            return v
        end


        def self.draw_dimension(e)
            block_name = e[2]
            cdef = Sketchup.active_model.definitions[block_name]
            if cdef
                ins = @entities.add_instance(cdef, [0,0,0])
                ins.name = "Dimension"
            end
        end

        def self.set_layer(ent)
            ent_layer = ent[8] || ent[0]
            ent_type = ent[0]
            #return if ent_type == "SEQEND"
            layers = Sketchup.active_model.layers
            if @in_block
                Sketchup.active_model.active_layer = layers[0]
                return
            end
            if @opts[:layers] == "by Dxf Type"
                layer = layers[ent_type]
                if layer.nil?
                    layer = layers.add(ent_type)
                end
                Sketchup.active_model.active_layer = layer
            elsif @opts[:layers] == "Layer0"
                Sketchup.active_model.active_layer = layers[0]
            elsif @opts[:layers] == "Dxf Layers"
                layer = layers[ent_layer]
                if layer.nil?
                    layer = layers.add(ent_layer)
                end
                Sketchup.active_model.active_layer = layer
            end
        end

        def self.find_by_handle()
            r= UI.inputbox(["Handle"], [""])
            #p r
            Sketchup.active_model.selection.clear
            for e in Sketchup.active_model.entities
                Sketchup.active_model.selection.add(e) if e.get_attribute("FreeDXF", "handle") == r[0]
            end
        end

        def self.get_layer(name)
            layers = Sketchup.active_model.layers
            layers.add(name)
        end

        def self.get_entities(name)
            name ||= "UNKOWN"
            if @layer_entities[name].nil?
                gr = @top_entities.add_group
                gr.name = name
                layer = get_layer(name)
                gr.layer = get_layer(name)
                @layer_entities[name] = gr.entities
                return @layer_entities[name]
            else
                return @layer_entities[name]
            end
        end
    end # module FreeDXF
end # module JF

unless file_loaded?(__FILE__)
    #submenu = UI.menu("Plugins").add_submenu("FreeDXF v#{FreeDXF::VERSION}")
    submenu = UI.menu("Plugins")
    submenu.add_item("FreeDXF v#{JF::FreeDXF::VERSION}") {JF::FreeDXF.main}
    if $JFDEBUG
        submenu.add_item("Find by Handle v#{JF::FreeDXF::VERSION}") {JF::FreeDXF.find_by_handle}
        UI.add_context_menu_handler do |menu|
            menu.add_item("Show DXF Handle") {
                h = Sketchup.active_model.selection[0].get_attribute("FreeDXF", "handle")
                UI.messagebox(h)
            }
        end
    end
    file_loaded(__FILE__)
end
