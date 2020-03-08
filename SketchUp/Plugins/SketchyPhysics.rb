# ------------------------------------------------------------------------------
# ** SketchyPhysics **
#
# Overview
#   SketchyPhysics is a real-time physics simulation plugin for SketchUp.
#
# Homepage
#   http://sketchucation.com/forums/viewforum.php?f=61
#
# Access
#   * (Menu) Plugins → SketchyPhysics → [option]
#   * (Menu) Plugins → SketchyReplay → [option]
#   * SketchyPhysics Toolbars
#
# Version
#   * 3.5.6 (Unofficial)
#   * NewtonDynamics 1.53
#
# Release Date
#   January 26, 2015
#
# Compatibility and Requirements
#   * SU6 or later (32 bit)
#   * Windows or Mac OS X 10.5 +
#     Mac OS X is not fully supported in terms of SketchyPhysics script API.
#     Some advanced SP scripted models will operate on Windows only as they use
#     Microsoft Windows API.
#
# Change Log
#
#   Version 3.5.6 - January 26, 2015
#     - Minor adjustment to the custom drag tool.
#     - Improved security for the two SU API adding methods.
#     - Resolved more compatibility issues with some prior SP models.
#     - Removed some unnecessary Ruby API adder methods. Thanks to ThomThom for
#       finding them.
#     - Fixed small gear joints bug. Thanks to Deskpilot for reporting.
#
#   Version 3.5.5 - October 25, 2014
#     - Reverted some changes to default shape to keep compatible with prior
#       versions. As well fixed a bug created in SP3.5.4 Thanks to faust07 for
#       report.
#
#   Version 3.5.4 - October 22, 2014
#     - Fixed a bug where flipped bodies didn't generate proper collisions.
#       Thanks to faust07 for report.
#
#   Version 3.5.3 - October 16, 2014
#     - Minor fixes and improvements.
#     - onTouch position parameter should be multiplied by the world scale.
#     - Added MSketchyPhysics3::SketchyPhysicsClient.#getLifetime(grp),
#       #getLifeStart(grp), #getLifeEnd(grp), and #getEmitter(grp).
#
#   Version 3.5.2 - September 24, 2014
#     - Flipped groups should no longer unflip when simulation starts.
#     - Scaled groups with convex collisions should no longer fall through other
#       bodies.
#     - Added MSketchyPhysics3::SP3xBodyContext.#getGlobalCentreOfMass to get
#       body centre of mass in global space.
#     - Made adjustments to the dialog, error handlers, and the drag tool.
#
#   Version 3.5.1 - September 13, 2014
#     - Converted all fixnum forces to float to prevent errors.
#     - Made new copyBody function compatible with prior scripted models,
#       specifically SP3RC1 Artillery by Mr.K.
#     - Stabilized shift flipped bodies technique which was added in SP3.5.
#     - Fixed a typo where centre of mass of convexhull2 and compound2 would
#       remain improper.
#     - Inspector should lookup joints in all shapes. Originally it looked up
#       joints within the default shape only.
#     - Updated homepage link
#
#   Version 3.5.0 - September 12, 2014
#     - Fixed tagName exception, a small error that would raise in Sketchy UI
#       from time to time.
#     - Fixed a glitch where Sketchy UI would fail to save if the dialog is
#       closed via the UI button.
#     - Joint limit inputs shall be able to interpret math operations. You can
#       type 100.mm and it will be converted to 3.94 inches automatically or
#       cos(60.degrees) and it will be evaluated to 0.50.
#     - Attributes to the newton body pointer, group scale, and some other
#       unused attributes shall be removed when simulation resets. Storing them
#       is not essential.
#     - Component/group axis are no longer modified. This change improves start
#       and reset simulation performance.
#     - Rewrote pick and drag tool, which relies its calculations on body centre
#       of mass, not group origin as originally intended. The original drag tool
#       required group axis be shifted to the bounds center (predefined centre of
#       mass). Changing the drag tool was an essential step because first, it no
#       longer required moving entity axis to the body centre of mass, second,
#       changing centre of mass via the setCentreOfMass function doesn't require
#       changing group axis, and third, the new drag tool is quite more flexible
#       than the original one. The new drag tool is adapted from the Newton
#       Dynamics physics utilities.
#     - Added Convexhull2 shape, which includes all sub groups in calculation of
#       convex collision, and maintains true centre of mass. Original convexhull
#       picks geometry one level deep, but does not gather geometry from groups
#       within the group. As well it does not have true centre of mass.
#       Convexhull2 was added to overcome such problems. Joints and all ignored
#       bodies are not included in collision calculation.
#     - Added Compound2 shape, which includes all sub groups in calculation of
#       compound collision, and maintains true centre of mass. Joints and all
#       ignored bodies are not included in collision calculation. Enable show
#       collision option to see the differences between Default and Compound2
#       shape.
#     - Added Staticmesh2 shape, which includes all faces of sub groups in
#       calculation of tree collision. Joints and all ignored groups are not
#       processed in part of the collision. Original staticmesh gathers faces
#       one level deep within the group, but does not search through groups
#       inside the main group; that's why staticmesh2 was added.
#     - MSketchyPhysics3::SP3xBodyContext.#getCentreOfMass should extract world
#       scale.
#     - Added MSketchyPhysics3::SP3xBodyContext.#setCentreOfMass(centre)
#     - Added MSketchyPhysics3::SP3xBodyContext.#getVolume - returns body volume
#       in cubic inches.
#     - Added MSketchyPhysics3::SP3xBodyContext.#getDensity - returns mass ratio
#       per cubic inch.
#     - Added MSketchyPhysics3::SP3xBodyContext.#getMatrix - returns body
#       transformation matrix.
#     - Added MSketchyPhysics3::SP3xBodyContext.#setMatrix(matrix) - similar to
#       teleport.
#     - Added MSketchyPhysics3::SP3xBodyContext.#continuousCollisionEnabled?
#     - Added MSketchyPhysics3::SP3xBodyContext.#continuousCollisionEnabled=(v)
#       Setting state to true will prevent body from passing other bodies at
#       high speeds, although this could alter performance at the same time.
#     - Added MSketchyPhysics3::SP3xBodyContext.#solid? to determine whether
#       body is collidable.
#     - Added MSketchyPhysics3::SP3xBodyContext.#collidable? which is same as
#       #.solid?
#     - Added MSketchyPhysics3::SP3xBodyContext.#collidable= which is same as
#       #.solid=
#     - Added MSketchyPhysics3::SP3xBodyContext.#magnetic? to determine whether
#       body is magnetic.
#     - Added MSketchyPhysics3::SketchyPhysicsClient.#pickAndDragEnabled=(v),
#       which is an equivalent to pick_drag_enabled=(v).
#     - Added MSketchyPhysics3::SketchyPhysicsClient.#pickAndDragEnabled?, which
#       is an equivalent to pick_drag_enabled?
#     - Fixed MSketchyPhysics3::SP3xCommonContext.#joy and .#joybutton methods.
#       Now, they should work if called from the scripted field too.
#     - Added MSketchyPhysics3::SP3xCommonContext.#stopSound(channel)
#     - Added MSketchyPhysics3::SP3xCommonContext.#stopAllSounds
#     - Added MSketchyPhysics3::SP3xCommonContext.#simulation which returns
#       $curPhysicsSimulation. Originally it was accessible from the scripted
#       field only. Now, its accessible from the controller fields too.
#     - Added MSketchyPhysics3::SP3xSimulationContext.#getFrameRate, which is an
#       equivalent to #frame_rate method.
#     - Added MSketchyPhysics3::SP3xSimulationContext.#getWorldScale
#     - Added MSketchyPhysics3::SP3xSimulationContext.#getGravity, which is an
#       equivalent to #gravity method.
#     - Added MSketchyPhysics3::SP3xSimulationContext.#setGravity(acceleration).
#     - Fixed a bug where staticmesh inside a group would force simulation to
#       crash. A staticmesh or compound within the group becomes default shape.
#     - Stabilized compatibility for SP3RC1, SP3.1, and SP3.2 scripted models.
#       Now, all advanced scripted models created in previous SP versions shall
#       work with SP3.5.
#     - Added continuous collision checkbox option to the emitter. Enabling this
#       will prevent emitted bodies from passing other bodies at high speeds.
#       Now, bullets will collide if CC is enabled.
#     - Added units of measurement to the joint limits. Thanks to Platinius for
#       request.
#     - Added scripting reference links to UI for easy reference destination.
#     - Fixed a glitch where objects would use 0.2 as default density, not the
#       assigned default density.
#
#   Version 3.4.1 - September 02, 2014
#     - Reverted some changes in SP Replay for compatibility with LightUp and
#       Skindigo.
#     - Added '(Menu) Plugins > Sketchy Physics > Erase All Attributes' option.
#
#   Version 3.4.0 - September 01, 2014
#     - Compatibility for Mac OS X. Thanks to Kevin (willeykj) for helping out.
#     - Fixed MIDI on new Mac OS X platforms
#       https://code.google.com/p/sketchyphysics/issues/detail?id=90
#       Thanks to Kevin (willeykj) for providing the fix in the post.
#     - Renamed folder back to SketchyPhysics3 for compatibility with prior
#       scripted models. You may want to remove original SketchyPhysics folder
#       from the Plugins folder.
#     - Changed the way errors are handled. All script errors will force
#       simulation to reset, displaying a message box with an error. Meanwhile,
#       all controller errors will be displayed in the Ruby Console, but keep
#       simulation running without breaking next tasks.
#     - Reverted some changes to remain compatible with the advanced scripted
#       models. I thought to add compatibility files at first, but did not want
#       to make it a hard task for scripters to migrate their advanced code to
#       3.4. I also added compatibility for SP3x and SP3RC1. Now all scripted
#       models from various SP versions shall work in 3.4. Although some
#       advanced scripted models created by me will not work because they modify
#       way too much. Keep in mind, a lot of scripted models will operate in
#       SU 2013 and below only. SU 2013 and lower use Ruby 1.8.x, while SU 2014
#       uses Ruby 2.0.0. There were Ruby implementation changes since 1.8.x.
#       These include, prohibited use of spaces between method name and the
#       parentheses, prohibited use of colons (:) in case-when statement, and
#       replaced Hash.#index with Hash.#key. As well, all models that use
#       LazyScript will operate in SU 2013 and below only. Some LazyScript
#       functions use Ruby DL, which is only available in Ruby 1.8.x categories.
#       SP 3.4, on SU 2014, uses Fiddle because DL is deprecated in Ruby 2.0.0.
#     - Added Sketchup::Group.#definition and Sketchup::ComponentInstance.#entities
#       for compatibility with prior scripted models. These are the only two
#       methods SP adds to Sketchup API. These methods shouldn't break any
#       plugins, but they may confuse a plugin developer.
#     - Included Math into Object for compatibility with prior models. Such
#       change shouldn't affect any plugins, but it may confuse the plugin
#       developer.
#     - Fixed minor controller inconsistencies and errors created while
#       rewriting the code in SP 3.3. Thanks to my brother Stas for finding the
#       bug at a very last moment before the upload.
#     - Fixed compound transformation shift. Thanks to Kris Yokoo and Joseph
#       Shawa for report. This is also a bug I introduced in SP 3.3.
#     - Fixed export animation in SU2014. Thanks to Werner_Hundt for report.
#     - Added start/commit operation to Sketchy Replay for better performance.
#     - Added export camera recording to Sketchy Replay. Thanks to faust07 for
#       report and Mr.K for writing the original script.
#     - Changed abort_operation back to commit_operation as abort_operation
#       is unsafe and breaks compatibility.
#     - Organized icons
#     - Made SketchyPhysicsClient and SketchyReplay compatible with the
#       Twilight Render.
#     - Added export animation to Kerkythea. You must have have Kerkythea plugin
#       installed in order for that feature to work. Thanks to tallbridgeguy for
#       request.
#     - Migrated from FFI to Fiddle. This reduces folder size, and allows SP to
#       operate on Mac OS X.
#     - Added MSketchyPhysics3::SP3xBodyContext.#static?
#     - Added MSketchyPhysics3::SP3xBodyContext.#static=(state)
#     - Added MSketchyPhysics3::SP3xBodyContext.#frozen?
#     - Added MSketchyPhysics3::SP3xBodyContext.#frozen=(state)
#     - Added MSketchyPhysics3::SP3xBodyContext.#getMass
#     - Added MSketchyPhysics3::SP3xBodyContext.#setMass(mass)
#     - Added MSketchyPhysics3::SP3xBodyContext.#recalculateMass(density)
#     - Added MSketchyPhysics3::SP3xBodyContext.#recalculateMassProperties - This
#       method assigns proper centre of mass to the body. SP defines entity
#       bounds center as centre of mass, which is incorrect in various cases.
#       This function calculates centre of mass using Newton function, which
#       presumes the correct centre of mass and moments of inertia.
#     - Added MSketchyPhysics3::SP3xBodyContext.#getCentreOfMass - Returns
#       centre of mass coordinates relative to the body transformation.
#     - Added MSketchyPhysics3::SP3xBodyContext.#this - returns self.
#     - Added MSketchyPhysics3::ControllerContext.#lookAt(nil) to destroy the
#       lookAt constraint.
#     - Added lookAt method to the MSketchyPhysics3::SP3xBodyContext.
#     - Added MSketchyPhysics3.getNewtonVersion.
#     - Improved MSketchyPhysics3::SP3xBodyContext.#breakit method. Plane size
#       shall not be fixed, but shall rely on the group bounds diagonal.
#     - Improved MSketchyPhysics3::SP3xBodyContext.split method. Split body
#       becomes static. Ideally it should be destroyed, but keeping it ensures
#       compatibility.
#     - onUntouch event shall be called even if onTouch/onTouching is not
#       included.
#     - Improved SP Sound UI. Fixed 'Play Sound' button and added 'Stop Sound'
#       button. Only WAVE sound format is supported. OGG doesn't seem to work.
#
#   Version 3.3.0 - July 20, 2014
#     - Compatible in SU2013, and SU2014.
#     - Replaced all Sketchup API modifying and adding methods, including
#       Sketchup::Group.#copy. Warning, this change prevents many scripted
#       models from working, especially those that rely on object entities.
#       ComponentInstance doesn't have a .entities method, but its definition
#       does. You will have to check before getting entities:
#           if ent.is_a?(Sketchup::ComponentInstnace)
#               ents = ent.definition.entities
#           elsif ent.is_a?(Sketchup::Group)
#               ents = ent.entities
#           end
#       Or use an available function: ents = MSketchyPhysics3.get_entities(ent).
#     - Minimized the use of global variables. Warning, this change prevents
#       many scripted models from working, especially LazyScript which depends
#       on $sketchyphysics_script_version variable. Use MSketchyPhysics::VERSION
#       instead. Many more global variables were removed as well; however,
#       $curPhysicsSimulation and $sketchyPhysicsToolInstance were not removed,
#       as they are quite handy.
#     - Improved script error handlers. Simulation will reset properly if an
#       error occurs. All detected errors, except those in joint controllers,
#       will force simulation to abort. Due to that change many models that were
#       uploaded with script errors will no longer work until they r' fixed.
#     - Fixed minor inspector dialog errors.
#           - Dialog clears when selection clears.
#           - Script can handle all sorts of escape characters.
#           - No longer throws two error messages.
#           - You're no longer required to click on the element to save the
#             written script.
#     - Rewrote most Ruby files, just to improve the way code looks and fixed
#       some minor bugs and inconsistencies. Note: This change could raise more
#       errors as I didn't pay much attention to what I did there. Need testers!
#     - Used Ruby DL to export functions for Ruby 1.8.x, used FFI to export
#       functions for Ruby 2.0.0.
#     - Added setSoundPosition2, which properly distributes 3d sound to the
#       left and right speakers, and controls volume depending by the specified
#       hearing range.
#     - Added drawPoints to simulation context, which allows you to draw points
#       with style.
#     - Added $sketchyPhysicsSimulationTool.cursorPos method - get cursor
#       position relative to view origin.
#     - Added more virtual key codes, 0-9 keys, semicolons, brackets, etc.
#     - Improved SP3xCommonContext.#key method. You may pass key values
#       to determine whether the specified key is down. This was added as a
#       backup technique if the desired key name is missing, you can pass key
#       constant value to get its up/down state.
#     - Emit bodies with original density. Previously copied bodies did not
#       have same density as the original bodies did. This is fixed now.
#     - Temporarily removed check for update as it would recommend downloading
#       SP3.2. Use SketchyUcation PluginStore instead.
#     - Added simulation.drawExt method, which basically behaves the same as
#       simulation.draw, but with more available types. Including, the 'line'
#       type yields GL_LINES rather than GL_LINE_STRIP like in the
#       simulation.draw method. The simulation.draw method was not replaced
#       just to remain compatible.
#     - View OpenGL drawn geometry is now included in the bounding box.
#     - Added ondraw { |view, bb| } - bb is the Geom::BoundingBox. Use it to add
#       3d points to the bounding box, so they don't get clipped. First, add
#       points and then draw.
#     - Used abort_operation rather than commit_operation to reset simulation.
#       This undoes most model changes made during simulation.
#     - Created joints will no longer add 'jointBlue' material...
#     - Removed MSketchyPhysics3::SketchyPhysicsClient.resetSimulation method.
#       Use MSketchyPhysics3::SketchyPhysicsClient.physicsStart to start.
#       Use MSketchyPhysics3::SketchyPhysicsClient.physicsReset to reset.
#       Use MSketchyPhysics3::SketchyPhysicsClient.physicsTogglePlay to play or
#       pause.
#       Use MSketchyPhysics3::SketchyPhysicsClient.paused? to determine whether
#       simulation is paused.
#       Use MSketchyPhysics3::SketchyPhysicsClient.active? to determine whether
#       simulation has started.
#     - Entity axis are no longer modified. They are modified, but they are set
#       back when simulation resets.
#     - Clears reference to all big variables at end, so garbage collection
#       cleans stuff up.
#     - Improved drag tool. Objects won't go to far, and lift object works
#       even if camera is looking from the top.
#     - Fix the glitch in joint connection tool where cursors didn't update.
#     - Added cursor access method.
#       $sketchyPhysicsToolInstance.getCursor - returns cursor id.
#       $sketchyPhysicsToolInstance.setCursor(id) - id: can be String, Symbol,
#       or Fixnum. Available names are select_plus, select_plus_minus, hand, and
#       target. For instance, set target cursor when creating FPS games:
#           onstart {
#               $sketchyPhysicsToolInstance.setCursor(:target)
#           }
#     - Added toggle pick and drag tool. When creating FPS games you might want
#       to disable the drag tool, so player can't pick bodies.
#       Use $sketchyPhysicsToolInstance.pick_drag_enabled = state (true or false)
#       Use $sketchyPhysicsToolInstance.pick_drag_enabled? to determine whether
#       the drag tool is enabled.
#       Example:
#           onstart {
#               $sketchyPhysicsToolInstance.pick_drag_enabled = false
#           }
#     - Added aliased event names:
#       onstart : onStart
#       onend : onEnd
#       ontick : onTick : onupdate :onUpdate
#       onpreframe : onPreFrame : onpreupdate :onPreUpdate
#       onpostframe : onPostFrame : onpostupdate :onPostUpdate
#       ontouch : onTouch
#       ontouching : onTouching
#       onuntouch : onUntouch
#       ondraw : onDraw
#       onclick : onClick
#       onunclick : onUnclick
#       ondoubleclick : onDoubleClick
#       ondrag : onDrag
#     - Improved record tool:
#       * Objects will move to their original positions when you press the
#         rewind button, regardless of when you started the recording.
#       * You may toggle recording any-time during simulation.
#       * Missing frames will no longer force the object to hide (move! 0).
#     - onDrag is called once a frame now (if the mouse is moved).
#     - Added onDoubleClick implementation.
#     - Added sp_tool which returns MSketchyPhysics3::SketchyPhysicsClient.
#     - Added sp_tool_instance which returns $sketchyPhysicsToolInstance.
#
# To Do
#   - Add more virtual keys to Mac OS X. You added semicolons and other symbols
#     to windows, but not to Mac. Fix it!
#   ~ Get rid of global getKeyState in input.rb.
#   - Work on sp_midi.rb
#   - Rewrite all dialogs. Use jquery. Have major web content in html, css, and
#     js files. Update dialog style.
#   - Improve joint API. Make each joint have its own joint context.
#     Connect/disconnect joint simply by creating/destroying the constraint.
#   - Avoid making components unique as this task affects modeller's work flow.
#     Commenting out all the .make_unique is not enough, the way collision is
#     generated needs to changed too. Meantime, use CTRL-Z after simulation
#     resets to undo most if not all changes done during simulation.
#   - Capture/Release mouse (For FPS games).
#   - Add particle effects, and more goodies from the LazyScript.
#   - Add explosion impact function.
#   - Add follow curve slider/piston joint.
#   - Upgrade to Newton 3.13 as it's way faster than Newton 1.53.
#   - Upgrade to SLD2 as it supports many different sound types. Consequently
#     change the way sounds are handled. Keep the reference to the sound type,
#     so we could use same list-box for all sound types.
#   - Investigate copied joints. Investigate why each joints needs a unique
#     name. Investigate why joints inside components are ignored.
#   - Add compound3 shape, where each triplet of face is an extruded convexhull.
#
# Licence
#   Copyright © 2009-2014, Chris Phillips
#
# Credits
#   * Juleo Jerez for the Newton Dynamics physics SDK.
#   * Kevin (willeykj) for the Mac the OS X version.
#   * Mr.K for Sketchy Replay with camera.
#   * Anton Synytsia for 3.3 - 3.5. Thanks to Mtriple for starting out ;)
#
# Author
#   Chris Phillips
#
# ------------------------------------------------------------------------------

require 'sketchup.rb'
require 'extensions.rb'

dir = File.dirname(__FILE__)

module MSketchyPhysics3

  NAME         = 'SketchyPhysics'.freeze
  VERSION      = '3.5.6'.freeze
  RELEASE_DATE = 'January 26, 2015'.freeze

  # Create the extension.
  @extension = SketchupExtension.new NAME, 'SketchyPhysics3/main.rb'

  desc = 'Realtime physics simulation plugin for SketchUp.'

  # Attach some nice info.
  @extension.description = desc
  @extension.version     = VERSION
  @extension.copyright   = 'Copyright © 2009-2015, Chris Phillips'
  @extension.creator     = 'Chris Phillips'

  # Register and load the extension on start-up.
  Sketchup.register_extension @extension, true

  class << self
    attr_reader :extension
  end

end
