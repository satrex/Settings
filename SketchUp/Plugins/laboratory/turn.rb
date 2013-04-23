require 'Sketchup'

     class FloatUpAnimation
       def nextFrame(view)
         new_eye = view.camera.eye
         new_eye.z = new_eye.z + 1.0
         view.camera.set(new_eye, view.camera.target, view.camera.up)
         view.show_frame
         return new_eye.z < 500.0
       end
     end

class TurnAnimation
  def nextFrame(view)
    tar = view.camera.target
    tar.x = tar.x + 0.5
    view.camera.set(view.camera.eye, tar, view.camera.up)
    view.show_frame
    return tar.x < 1
  end

end

def turn
       Sketchup.active_model.active_view.animation = TurnAnimation.new
end

turn
