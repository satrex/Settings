require 'Sketchup'

def move_camera
  eye = [100, 1000, 1000]
  target = [0, 0, 0]
  up = [0, 0, 1]
  my_camera= Sketchup::Camera.new eye, target, up  

  view = Sketchup.active_model.active_view
  view.camera = my_camera
end
 plugins_menu = UI.menu("Plugins") 
 item = plugins_menu.add_item("funi") { move_camera }
 file_loaded(__FILE__)
