# This file is loaded every time a new model is opened to undo most changes done
# by other scripted models.

$sketchyphysics_version_loaded = 3.4

class SP3xBodyContext

  def initEvents(events_grp)
    initEvents_standard(events_grp)
  end

end # class SP3xBodyContext


class SP3xSimulationContext

  def doOnStart
    doOnStart_standard
  end

  def doOnEnd
    doOnEnd_standard
  end

  def doOnTick(frame = 0)
    doOnTick_standard(frame)
  end

  def doPreFrame
    doPreFrame_standard
  end

  def doPostFrame
    doPostFrame_standard
  end

end # class SP3xSimulationContext


class SketchyPhysicsClient

  def initialize
    initialize_standard
  end

  def activate
    activate_standard(true)
  end

  def deactivate(view)
    deactivate_standard
  end

  def nextFrame(view)
    nextFrame_standard
  end

  def draw(view)
    draw_standard(view)
  end

  def handleOnTouch(bodies, speed, pos)
    handleOnTouch_standard(bodies, speed, pos)
  end

  def resetSimulation
    resetSimulation_standard
  end

  def self.startphysics
    self.physicsStart
  end

  def self.physicsReset
    self.safePhysicsReset
  end

end # class SketchyPhysicsClient
