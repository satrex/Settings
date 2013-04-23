require 'Sketchup'

def offset 
  model = Sketchup.active_model
  selection = model.selection
  selection.each{|entity|
    UI.messagebox(entity.typename)
    }
end

offset

