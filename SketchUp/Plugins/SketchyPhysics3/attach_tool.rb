require 'sketchup.rb'

module MSketchyPhysics3

  def showPopup(x,y)
    # Create
    dlg = UI::WebDialog.new('AttachTool', false, 'Garbage'+rand.to_s, 100, 150, x, y, false)
    fn = File.dirname(__FILE__) + '/SketchyUI/attachTool.html'
    dlg.set_file fn
    dlg.show {
      # dlg.set_position(x,y)
      # dlg.set_size(100,50)
    }
    # Create a callback for anytime a value changes in the dialog.
    dlg.add_action_callback("ValueChanged") {|d,p|
      puts p
    }
  end

  class DOF
    def initialize(type)
      @bfixed = false
      @type = type
      @min = 0.0
      @max = 0.0
      @accel = 0.0
      @damp = 0.0
      @springStiff = 0.0
      @springDamp = 0.0
      @desiredOffset = 0.0
      @friction = 0.0

      case type
        when 'hinge'
          @limits = []
      end
    end
  end

  class AJoint
    def initialize()
      @xform = Geom::Transformation.new()
      @children = []
      @linearLimits
      @rotationLimits
      @minRotation = 0.0
      @maxRotation = 0.0
      @minPosition = 0.0
      @maxPosition = 0.0
      @desiredRotation = 0.5
      @desiredPosition = 0.5
    end
  end

  class AHinge
    def initialize()
      @xform = Geom::Transformation.new()
      @children = []
    end
  end

  class Attachment
    def initialize(child, parent)
      @child = child
      @parent = parent
      @jointType = nil
      @jointXform = nil
    end
  end

end # module MSketchyPhysics3
