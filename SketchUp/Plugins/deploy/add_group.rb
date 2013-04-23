require 'Sketchup'

def add_group
 depth = 100
 width = 100
 height = 100
 model = Sketchup.active_model
 entities = model.active_entities
 pts = []
 pts[0] = [0, 0, 0]
 pts[1] = [width, 0, 0]
 pts[2] = [width, depth, 0]
 pts[3] = [0, depth, 0]
 # Add the group to the entities in the model
 group = entities.add_group

 # Get the entities within the group
 entities2 = group.entities

 # Add a face to within the group
 face = entities2.add_face pts
 status = face.pushpull -1 * height, false
 group.description = "This is a Group with a 2d Face"
 description = group.description

 group.entities.add_line([0,0,0],[100,100,100])
 transformation = Geom::Transformation.new([100,0,0])

 group2 = group.entities.add_group
 pts2 = []
 offset = 0.2 * width
 pts2[0] = [-1 * offset, -1 * offset, height]
 pts2[1] = [width + offset, -1 * offset, height]
 pts2[2] = [width + offset, depth + offset, height]
 pts2[3] = [-1 * offset, depth + offset, height]
 
 entities3 = group2.entities
 face2 = entities3.add_face pts2
 mid1 = [width / 2, -1 * offset, height + 50]
 mid2 = [width / 2, depth + offset, height + 50]
 mid_line = entities3.add_line mid1, mid2
 entities3.add_line mid1, pts2[0]
 entities3.add_line mid1, pts2[1]

 entities3.add_line mid2, pts2[2]
 entities3.add_line mid2, pts2[3]
entities3.add_face mid1, pts2[0], pts2[3], mid2
entities3.add_face mid1, pts2[1], pts2[2], mid2
entities3.add_face mid1, pts2[0], pts2[1]
entities3.add_face mid2, pts2[2], pts2[3]
  
 vector = Geom::Vector3d.new 0,0,50
 trans = Geom::Transformation.new vector
 mid1.transform! trans
 mid2.transform! trans

 # Note that local_bounds_1 and local_bounds_2 will be identical, since
 # they both find the bounding box in group's untransformed state.
 local_bounds_1 = group.local_bounds
 group.transform! transformation
 local_bounds_2 = group.local_bounds

end
 plugins_menu = UI.menu("Plugins") 
 item = plugins_menu.add_item("add_small_house") { add_group }
 file_loaded(__FILE__)
