# dxf.rb - (C) 2011 jim.foltz@gmail.com
# $Id$

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

module Dxf

    class Entity
        # Base class for Dxf entities providing common properties.
        # A Dxf "Entity" is a Graphical Object. Non-graphical Dxf objects are called "objects."

        def initialize(entity_type = "UNKNOWN")
            @codes = Hash.new
            update(0, entity_type)
        end
        #
        # @return [nil]
        # @param [c] the group code
        # @param [v] the value associated with the code.
        # @param [c, v] a code and value
        # Adds the code and value to the internal @codes Hash.
        def update(c, v)
            if @codes[c].nil?
                @codes[c] = v
            elsif @codes[c].class == Array
                @codes[c] << v
            else
                t = @codes[c]
                @codes[c] = []
                @codes[c] << t
                @codes[c] << v
            end
        end

        # A method to perform some validity checks for entities.
        # This is called on the @last_entity just before creating a new entity via Entities#create_entity.
        def verify
        end

        # Properties that apply to all Dxf Entities (dxf graphical objects)

        # DXF handle (unique ID.)
        # @return [String] 
        def handle
            @codes[5]
        end

        # @return [String] The layer name.
        def layer_name
            @codes[8]
        end
        def paper_space?
            not paper_space?
        end
        def model_space?
            @codes.fetch(67, 0) == 0
        end
    end # class Entity

    class Vertex   < Entity
        #attr_reader :location
        def initialize(entity_type = "VERTEX")
            super
        end
        def location
            [ @codes[10], @codes[20], @codes.fetch(30, 0.0) ]
        end
        def bulge
            @codes.fetch(42, 0.0)
        end
        def starting_width
            @codes.fetch(40, 0.0)
        end
        def ending_width
            @codes.fetch(41, 0.0)
        end
        def flags
            # 1   = Extra vertex created by curve-fitting
            # 2   = Curve-fit tangent defined for this vertex. A curve-fit tangent direction of 0 may be omitted
            #       from DXF output but is significant if this bit is set
            # 4   = Not used
            # 8   = Spline vertex created by spline-fitting
            # 16  = Spline frame control point
            # 32  = 3D polyline vertex
            # 64  = 3D polygon mesh
            # 128 = Polyface mesh vertex
            @codes[70]
        end
    end

    class Line     < Entity
        def initialize(type = "LINE")
            super
        end
        def start_point
            [ @codes[10], @codes[20], @codes.fetch(30, 0.0) ]
        end
        def end_point
            [ @codes[11], @codes[21], @codes.fetch(31, 0.0) ]
        end
        # Optional, default = 0
        def thickness
            @codes.fetch(39, 0.0)
        end
        def extrusion_direction
            # Optional; default = [0, 0, 1]
            # @default = [0, 0, 1]
            [ @codes.fetch(210, 0.0), @codes.fetch(220, 0.0), @code.fetch(230, 1.0) ]
        end
    end

    class Polyline < Entity
        attr_reader :vertices
        def initialize(type = "POLYLINE")
            @vertices = []
            super
        end
        def add_vertex(v)
            @vertices << v
        end
    end

    class Circle   < Entity
        def initialize(type = "CIRCLE")
            super
        end
        def center
        end
        def radius
        end
    end

    class LwPolyline < Entity
        # A Light-weight Polyline.
        def initialize(type = "LWPOLYLINE")
            @last_code = nil
            super
            @codes[10] = []
            @codes[20] = []
            @codes[42] = []
        end
        # If the length of 10, 20, and 42 are not equal when the next 10 is read, add a 0 to 42.
        def update(c, v)
            #if @last_code == 20 and c != 42
                #super(42, 0.0)
            #end
            @last_code = c
            #if c == 10 and (@codes[10].length > @codes[42].length)
                #puts "adding zero:#{@codes[5]}"
                #@codes[42].push(0.0)
                #super(42, 0.0)
            #end
            if c == 10
                @codes[42].push(0.0)
            end
            if c == 42
                @codes[42][-1] = v
                return
            end
            super(c, v)
        end
        def verify
            puts "bad verts #{handle}" if @codes[42].length != @codes[10].length
        end
    end

    class Entities
        # A collection for Dxf Entity objects.
        attr_reader :last_entity
        def initialize
            @entities = []
            @verts = []
            @polyline = nil
            @last_entity = nil
        end

        def create_entity(type)
            @last_entity.verify if @last_entity
            case type
                #when "ENDSEC"
                #    @last_entity = nil
            when "LINE"
                @last_entity = Line.new
                @entities.push(@last_entity)
            when "CIRCLE"
                @last_entity = Circle.new
                @entities.push(@last_entity)
            when "POLYLINE"
                @polyline = Polyline.new
                @last_entity = @polyline
                @entities.push(@last_entity)
            when "VERTEX"
                vertex = Vertex.new
                @polyline.add_vertex(vertex) if @polyline
                @last_entity = vertex
            when "SEQEND"
                @polyline = nil if @polyline
            when "LWPOLYLINE"
                @last_entity = LwPolyline.new
                @entities.push(@last_entity)
            else
                # Create a generic Entity
                @last_entity = Entity.new(type)
                # Then, throw it away for now.
                #@entities.push(@last_entity)
            end
        end
        def each
            #return unless block_given?
            raise "No block given in\n#{__FILE__} line #{__LINE__}." unless block_given?
            @entities.each { |entity| yield(entity) }
        end
        def empty?
            @entities.empty?
        end
        def length
            @entities.length
        end

    end # class Entities

    class Block
        attr_reader :entities
        def initialize
            @last_entity = nil
            @codes = { 0 => "BLOCK" }
            @entities = Dxf::Entities.new
        end
        def update(c, v)
            if @codes[c].nil?
                @codes[c] = v
            elsif @codes[c].class == Array
                @codes[c] << v
            else
                t = @codes[c]
                @codes[c] = []
                @codes[c] << t
                @codes[c] << v
            end
        end
        #end
    end # class Block

    class Blocks
        attr_reader :last_block
        def initialize
            @blocks = []
            @last_block = nil
            @container = nil
        end
        def create_block
            last_block = Dxf::Block.new
            @blocks.push(last_block)
            @last_block = last_block
        end
        def each
            @blocks.each {|block| yield(block) }
        end
    end

end # module Dxf

module DxfTest

    module_function

    def parse(filename)
        @debug = $JFDEBUG
        fp = File.open(filename)

        dxf = {
            'HEADER' => {},
            'BLOCKS' => Dxf::Blocks.new,
            'ENTITIES' => Dxf::Entities.new
        }
        last_code = nil

        #
        # main loop
        #

        c = v = nil
        while v != "EOF"
            c, v = read_codes(fp)
            if v == "SECTION"
                c, v = read_codes(fp)

                if v == "HEADER"
                    hdr = dxf['HEADER']
                    while true
                        c, v = read_codes(fp)
                        break if v == "ENDSEC"
                        if c == 9
                            key = v
                            hdr[key] = {}
                        else
                            add_att(hdr[key], c, v)
                        end
                    end # while
                end # if HEADER

                if v == "BLOCKS"
                    blks = dxf[v]
                    in_ent = false
                    in_blk = false
                    while true
                        c, v = read_codes(fp)
                        break if v == "ENDSEC"
                        if v == "ENDBLK"
                            in_ent = false
                            in_blk = false
                            next
                        end
                        if c == 0 and v == "BLOCK"
                            blk = blks.create_block
                            in_blk = true
                            next
                        end
                        if c == 0 and v != "ENDBLK"
                            blks.last_block.entities.create_entity(v)
                            in_ent = true
                            next
                        end
                        if in_ent
                            blks.last_block.entities.last_entity.update(c, v)
                        elsif in_blk
                            blks.last_block.update(c, v)
                        end
                    end # while
                end # if BLOCKS

                if v == "ENTITIES"
                    entities = dxf[v]
                    c, v = read_codes(fp)
                    while v != "ENDSEC"
                        if c == 0
                            entities.create_entity(v)
                        else
                            entities.last_entity.update(c, v)
                        end
                        c, v = read_codes(fp)
                    end
                end

            end # if in SECTION

        end # main loop

        return dxf
    end

    def read_codes(fp)
        c = fp.gets.to_i
        v = fp.gets.strip
        v.upcase! if c == 0
        case c
        when 10..59, 140..147, 210..239, 1010..1059
            v = v.to_f
        when 60..79, 90..99, 170..175,280..289, 370..379, 380..389,500..409, 1060..1079
            v = v.to_i
        end
        codes = [c, v]
        return(codes)
    end

    def add_att(ent, code, value)
        if ent.nil? and @debug
            p caller
            p code
            p value
        end
        if ent[code].nil?
            ent[code] = value
        elsif ent[code].class == Array
            ent[code] << value
        else
            t = ent[code]
            ent[code] = []
            ent[code] << t
            ent[code] << value
        end
    end


end # class Dxf2Ruby


if $0 == __FILE__
    require 'pp'
    t1 = Time.now
    dxf = DxfTest.parse(ARGV.shift)
    puts "Finsihed in #{Time.now - t1}"
    #dxf['ENTITIES'].each { |e| pp e; puts }
    #dxf["BLOCKS"].each { |b| pp b; puts }
    pp dxf
end
