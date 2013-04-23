require 'Sketchup'
  mymenu = UI.menu('Plugins').add_submenu('satrex')
mymenu.add_item('move camera') {

  eye = [10000, 1000, 1000]
  target = [0, 0, 0]
  up = [0, 0, 1]
  my_camera= Sketchup::Camera.new eye, target, up  

  view = Sketchup.active_model.active_view
  view.camera = my_camera
}
