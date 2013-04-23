require 'Sketchup'

def getPointsByDistance width, depth
    sw = [0,0,0]
    nw = [depth, 0, 0]
    ne = [depth, width, 0]
    se = [0, width, 0]
   model = Sketchup.active_model
    entities = model.active_entities
 
    entities.add_line sw, nw    
    entities.add_line nw, ne    
    entities.add_line ne, se    
    entities.add_line se, sw   
    bottom = entities.add_face ne, se, sw, nw

    kiso_height = 50
    bottom.pushpull -1 * kiso_height true

    get_above = Geom::Vector.new (0,0,kiso_height)
    get_smaller = Geom::Transformation.scaling [depth / 2, width / 2, kiso_height], 0.8
    swu = sw.offset get_above
    nwu = nw.offset get_above
    neu = ne.offset get_above
    seu = se.offset get_above
    entities.add_line 

    mouth = bottom.
end

getPointsByDistance 500, 800
