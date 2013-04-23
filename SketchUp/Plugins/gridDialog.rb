require 'Sketchup'

def show_grid_dialog
  dlg_html=openUiHtml
  dlg = UI::WebDialog.new('Draw Grid', true,'MyDialog', 200, 100, 150, 150, true)
  dlg.navigation_buttons_enabled = false
  dlg.set_html(dlg_html)
  dlg.add_action_callback("on_ok") {|d,p|
    x = d.get_element_value("x")
    y = d.get_element_value("y")
    puts y
    # d.execute_script("draw_grid(x, y)");
    draw_grid(x.to_i, y.to_i)
  }
  dlg.show
end

def draw_grid (x, y)
  model = Sketchup.active_model
  ents = model.entities
  scale = 303.mm
  group = Sketchup.active_model.entities.add_group
  puts x

  a = [0, 0, 0]
  vector1 = Geom::Vector3d.new(x * scale,0,0)
  b = a.offset vector1

  puts x * scale
  vector2 = Geom::Vector3d.new(x * scale, y * scale, 0)
  c = a.offset vector2

  vector3 = Geom::Vector3d.new(0, y * scale, 0)
  d = a.offset vector3

  points = [a, b, c, d] 
#  face = group.entities.add_face points
  i = 0
  until i > x
   start_point = Geom::Point3d.new(i * scale ,0,0)
   end_point = Geom::Point3d.new(i * scale ,y * scale,0)
   group.entities.add_line start_point, end_point 
   i = i + 1
  end
  j = 0
  until j > y 
   start_point = Geom::Point3d.new(0,j * scale ,0)
   end_point = Geom::Point3d.new(x * scale ,j * scale,0)
   group.entities.add_line start_point, end_point 
   j = j + 1
  end 
  group.name="Grid"
  group.locked=true
end

def openUiHtml


filename = '/Library/Application Support/Google SketchUp 8/SketchUp/plugins/grid_dialog.html'

htmlDoc = ''

f = File.open(filename)
f.each { |line|
    htmlDoc.concat line
}
puts htmlDoc
f.close
htmlDoc
  end 


unless file_loaded?(__FILE__)
  mymenu = UI.menu('Plugins').add_submenu('satrex')
  mymenu.add_item('Grid Drawer') {show_grid_dialog}
  file_loaded(__FILE__)
end

