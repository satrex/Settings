require 'sketchup.rb'

dir = File.dirname(__FILE__)
$LOAD_PATH.insert(0, dir)

# List of all global variables in SP
$spExperimentalFeatures = true
$bSPDoRecord = false
$spReplayCamera = false
$spMovieMode = false
$spObjectInspector = nil
$sketchyPhysicsToolInstance = nil
$curPhysicsSimulation = nil
$curEvalGroup = nil
$curEvalTouchingGroup = nil
# The following global variables are used in SP but are never created.
# $sketchyViewerDialog = nil
# $debug = nil

# Version variable for compatibility.
$sketchyphysics_version_loaded = MSketchyPhysics3::VERSION.to_f

begin
  require 'class_extensions.rb'
  require 'newton.rb'
  require 'virtual_key_codes.rb'
  require 'input.rb'
  require 'midi.rb'
  require 'sound.rb'
  require 'controller_commands.rb'
  require 'sp_util.rb'
  require 'control_panel.rb'
  require 'inspector.rb'
  require 'prims_tool.rb'
  require 'box_prim_tool.rb'
  require 'joint_tool.rb'
  require 'joint_connection_tool.rb'
  require 'attach_tool.rb'
  require 'sketchy_replay.rb'
  require 'sp_tool.rb'
  #~ require 'child_frame.rb'
  #~ require 'sp_midi.rb'
rescue Exception => e
  err = RUBY_VERSION =~ /1.8/ ? "#{e}\n\n#{e.backtrace.join("\n")}" : e
  raise err
ensure
  $LOAD_PATH.delete_at(0)
end

unless file_loaded?(__FILE__)

  menu = UI.menu('Plugins').add_submenu('SketchyPhysics')
  help_menu = UI.menu('Help')

  menu.add_item('Physics Settings'){
    MSketchyPhysics3.editPhysicsSettings
  }

  menu.add_item('Buoyancy Settings'){
    MSketchyPhysics3.setupBuoyancy
  }

  menu.add_item('Sounds'){
    MSketchyPhysics3.soundEmbedder
  }

  menu.add_item('Erase All Attributes'){
    msg = "This option removes all SP attributes including saved body script.\n"
    msg << "Are you sure you want to continue?"
    next if UI.messagebox(msg, MB_YESNO) == IDNO
    model = Sketchup.active_model
    if Sketchup.version.to_i > 6
      model.start_operation('Remove SP Atrributes', true)
    else
      model.start_operation('Remove SP Atrributes')
    end
    model.definitions.each { |cd|
      cd.instances.each { |inst|
        atr = inst.attribute_dictionaries
        next unless atr
        atr.delete('SPOBJ')
        atr.delete('SPTAKE')
        inst.layer = 'Layer0' if (inst.is_a?(Sketchup::Text) && atr['SketchyPhysics'])
        atr.delete('SketchyPhysics')
      }
    }
    model.entities.grep(Sketchup::Text).each { |ent|
      atr = ent.attribute_dictionaries
      next unless atr
      ent.layer = 'Layer0' if atr['SketchyPhysics']
      atr.delete('SketchyPhysics')
    }
    model.attribute_dictionaries.delete('SPRECORD')
    model.attribute_dictionaries.delete('SPSETTINGS')
    model.attribute_dictionaries.delete('sketchyphysics')
    model.attribute_dictionaries.delete('SketchyPhysics')
    msg = "Would you like to erase all SP joints as well?"
    to_remove = []
    if UI.messagebox(msg, MB_YESNO) == IDYES
      model.definitions.each { |cd|
        cd.instances.each { |inst|
          if inst.attribute_dictionaries && inst.attribute_dictionaries['SPJOINT']
            to_remove << inst
          end
        }
      }
    end
    to_remove.each { |e| e.erase! if e.valid? }
    to_remove.clear
    model.definitions.purge_unused
    model.materials.purge_unused
    model.layers.purge_unused
    model.styles.purge_unused
    model.commit_operation
  }

  menu.add_separator

  menu.add_item('Homepage'){
    UI.openURL("http://sketchucation.com/forums/viewtopic.php?f=61&t=58936")
  }

  menu.add_item('Wiki'){
    UI.openURL("http://sketchyphysics.wikia.com/wiki/SketchyPhysicsWiki")
  }

  about_msg = "SketchyPhysics #{MSketchyPhysics3::VERSION} -- #{MSketchyPhysics3::RELEASE_DATE}\n"
  about_msg << "Powered by the Newton Dynamics #{MSketchyPhysics3.getNewtonVersion} Physics SDK.\n"
  about_msg << "Copyright © 2009-2014, Chris Phillips\n\n"
  about_msg << "Use SketchUcation PluginStore to check for updates."

  menu.add_item('About'){ UI.messagebox(about_msg) }

  #~ help_menu.add_separator
  #~ help_menu.add_item('About SketchyPhysics'){ UI.messagebox(about_msg) }

  # ----------------------------------------------------------------------------
  # Create simulation toolbar
  # ----------------------------------------------------------------------------


  toolbar = UI::Toolbar.new 'SketchyPhysics'

  cmd = UI::Command.new('Play'){
    MSketchyPhysics3::SketchyPhysicsClient.physicsTogglePlay
  }
  cmd.set_validation_proc {
    next MF_UNCHECKED unless MSketchyPhysics3::SketchyPhysicsClient.active?
    MSketchyPhysics3::SketchyPhysicsClient.paused? ? MF_UNCHECKED : MF_CHECKED
  }
  cmd.menu_text = cmd.tooltip = 'Toggle Play'
  cmd.status_bar_text = 'Play/Pause physics simulation.'
  cmd.small_icon = 'images/small/toggle_play.png'
  cmd.large_icon = 'images/large/toggle_play.png'
  toolbar.add_item(cmd)


  cmd = UI::Command.new('Reset'){
    MSketchyPhysics3::SketchyPhysicsClient.physicsReset
  }
  cmd.set_validation_proc {
    MSketchyPhysics3::SketchyPhysicsClient.active? ? MF_ENABLED : MF_GRAYED
  }
  cmd.menu_text = cmd.tooltip = 'Reset'
  cmd.status_bar_text = 'Reset physics simulation.'
  cmd.small_icon = 'images/small/rewind.png'
  cmd.large_icon = 'images/large/rewind.png'
  toolbar.add_item(cmd)


  cmd = UI::Command.new('ShowUI'){
    $spObjectInspector.toggleDialog
  }
  cmd.set_validation_proc {
    $spObjectInspector.dialogVisible? ? MF_CHECKED : MF_UNCHECKED
  }
  cmd.menu_text = cmd.tooltip = 'UI'
  cmd.status_bar_text = 'Show/Hide UI dialog.'
  cmd.small_icon = 'images/small/ui.png'
  cmd.large_icon = 'images/large/ui.png'
  toolbar.add_item(cmd)


  cmd = UI::Command.new('JointConnectionTool'){
    model = Sketchup.active_model
    if MSketchyPhysics3::JointConnectionTool.active?
      model.select_tool nil
      model.selection.clear
    else
      model.select_tool MSketchyPhysics3::JointConnectionTool.new
    end
  }
  cmd.set_validation_proc {
    MSketchyPhysics3::JointConnectionTool.active? ? MF_CHECKED : MF_UNCHECKED
  }
  cmd.menu_text = cmd.tooltip = 'Joint Connector'
  cmd.status_bar_text = 'Activate/Deactivate joint connection tool.'
  cmd.small_icon = 'images/small/joint_connector.png'
  cmd.large_icon = 'images/large/joint_connector.png'
  toolbar.add_item(cmd)

  toolbar.show


  # ----------------------------------------------------------------------------
  # Create sketchy replay toolbar
  # ----------------------------------------------------------------------------


  toolbar = UI::Toolbar.new('SketchyReplay')
  $bSPDoRecord = false
  $spMovieMode = false
  replayAnimation = nil

  cmd = UI::Command.new('Record'){ $bSPDoRecord = !$bSPDoRecord }
  cmd.set_validation_proc {
    $bSPDoRecord ? MF_CHECKED : MF_UNCHECKED
  }
  cmd.small_icon = 'images/small/replay_record.png'
  cmd.large_icon = 'images/large/replay_record.png'
  cmd.menu_text = cmd.tooltip = 'Record'
  cmd.status_bar_text = 'Check to record simulation.'
  toolbar.add_item cmd


  cmd = UI::Command.new('RepalyCamera'){ $spReplayCamera = !$spReplayCamera }
  cmd.set_validation_proc {
    $spReplayCamera ? MF_CHECKED : MF_UNCHECKED
  }
  cmd.small_icon = 'images/small/replay_camera.png'
  cmd.large_icon = 'images/large/replay_camera.png'
  cmd.menu_text = cmd.tooltip = 'Replay Camera'
  cmd.status_bar_text = 'Check to replay camera.'
  toolbar.add_item cmd


  cmd = UI::Command.new('Play'){
    unless replayAnimation
      replayAnimation = SketchyReplay::SketchyReplay.new
    end
    replayAnimation.play
  }
  cmd.set_validation_proc {
    next MF_UNCHECKED unless replayAnimation
    replayAnimation.paused? ? MF_UNCHECKED : MF_CHECKED
  }
  cmd.small_icon = 'images/small/replay_toggle_play.png'
  cmd.large_icon = 'images/large/replay_toggle_play.png'
  cmd.menu_text = cmd.tooltip = 'Replay'
  cmd.status_bar_text = 'Play/Pause animation.'
  toolbar.add_item cmd


  cmd = UI::Command.new('Rewind'){
    replayAnimation.rewind if replayAnimation
  }
  cmd.small_icon = 'images/small/replay_rewind.png'
  cmd.large_icon = 'images/large/replay_rewind.png'
  cmd.menu_text = cmd.tooltip = 'Rewind'
  cmd.status_bar_text = 'Reset animation, set objects to original placement.'
  toolbar.add_item cmd


  cmd = UI::Command.new('Reverse'){
    replayAnimation.reverse if replayAnimation
  }
  cmd.small_icon = 'images/small/replay_reverse.png'
  cmd.large_icon = 'images/large/replay_reverse.png'
  cmd.menu_text = cmd.tooltip = 'Reverse'
  cmd.status_bar_text = 'Reverse animation.'
  toolbar.add_item cmd


  cmd = UI::Command.new('RecordMovie'){
    $spMovieMode = !$spMovieMode
  }
  cmd.set_validation_proc {
    $spMovieMode ? MF_CHECKED : MF_UNCHECKED
  }
  cmd.small_icon = 'images/small/replay_movie.png'
  cmd.large_icon = 'images/large/replay_movie.png'
  cmd.menu_text = cmd.tooltip = 'Movie Mode'
  cmd.status_bar_text = 'Toggle movie mode.'
  #~ toolbar.add_item cmd


  submenu = UI.menu('Plugins').add_submenu('SketchyReplay')
  submenu.add_item('Export to KerkyThea'){
    SketchyReplay.export_to_kerkythea
  }
  submenu.add_item('Export Animation'){
    sr = SketchyReplay::SketchyReplay.new
    sr.export
  }
  submenu.add_item('Erase Record'){
    model = Sketchup.active_model
    if Sketchup.version.to_i > 6
      model.start_operation('Export SP to Kerkythea', true)
    else
      model.start_operation('Export SP to Kerkythea')
    end
    model.definitions.each { |cd|
      cd.instances.each { |ci|
        ci.delete_attribute('SPTAKE', 'samples')
      }
    }
    model.attribute_dictionaries.delete('SPRECORD')
    model.commit_operation
  }
  submenu.add_separator
  submenu.add_item('About'){
    UI.messagebox("Version 1.6.0\nWritten by Chris Phillips.")
  }

  toolbar.show


  # ----------------------------------------------------------------------------
  # Create joints toolbar
  # ----------------------------------------------------------------------------


  toolbar = UI::Toolbar.new 'SketchyPhysics Joints'

  # gear pulley wormgear
  %w(hinge slider servo piston motor gyro fixed).each do |joint|
    cmd = UI::Command.new(joint.capitalize){
      Sketchup.active_model.select_tool(MSketchyPhysics3::CreateJointTool.new(joint))
    }
    cmd.menu_text = cmd.tooltip = joint.capitalize
    cmd.status_bar_text = "Create a #{joint} joint."
    cmd.small_icon = "images/small/#{joint}.png"
    cmd.large_icon = "images/large/#{joint}.png"
    toolbar.add_item(cmd)
  end

  toolbar.add_separator
  # removed: oscillator magnet
  %w(corkscrew spring ball universal).each do |joint|
    cmd = UI::Command.new(joint.capitalize){
      Sketchup.active_model.select_tool(MSketchyPhysics3::CreateJointTool.new(joint))
    }
    cmd.menu_text = cmd.tooltip = joint.capitalize
    cmd.status_bar_text = "Create a #{joint} joint."
    cmd.small_icon = "images/small/#{joint}.png"
    cmd.large_icon = "images/large/#{joint}.png"
    toolbar.add_item(cmd)
  end

  toolbar.restore

  UI.add_context_menu_handler { |menu|
    selection = Sketchup.active_model.selection
    # Copy joint
    # Make joint unique (only needed if copied)
    if selection.single_object? && selection.first.get_attribute('SPJOINT', 'type', nil) != nil
      joint = selection.first
      jointType = joint.get_attribute('SPJOINT', 'type', nil)
      menu.add_item('  Joint Settings'){ setJointSettings }
      # submenu = menu.add_submenu(' Joint:' + jointType)
      # submenu.add_item('    Find Children'){}
    end
  }


  # ----------------------------------------------------------------------------
  # Create prisms toolbar
  # ----------------------------------------------------------------------------


  toolbar = UI::Toolbar.new('Sketchy Solids')

  cmd = UI::Command.new('Box'){ MSketchyPhysics3.createPrim('box') }
  cmd.small_icon = 'images/small/box.png'
  cmd.large_icon = 'images/large/box.png'
  cmd.menu_text = cmd.tooltip = 'Create box'
  cmd.status_bar_text = 'Create a rectangular prism.'
  toolbar.add_item cmd


  cmd = UI::Command.new('Sphere'){ MSketchyPhysics3.createPrim('sphere') }
  cmd.small_icon = 'images/small/sphere.png'
  cmd.large_icon = 'images/large/sphere.png'
  cmd.menu_text = cmd.tooltip = 'Create sphere'
  cmd.status_bar_text = 'Create a sphere.'
  toolbar.add_item cmd


  cmd = UI::Command.new('Cylinder'){ MSketchyPhysics3.createPrim('cylinder') }
  cmd.small_icon = 'images/small/cylinder.png'
  cmd.large_icon = 'images/large/cylinder.png'
  cmd.menu_text = cmd.tooltip = 'Create cylinder'
  cmd.status_bar_text = 'Create a cylinder.'
  toolbar.add_item cmd


  cmd = UI::Command.new('Cone'){ MSketchyPhysics3.createPrim('cone') }
  cmd.small_icon = 'images/small/cone.png'
  cmd.large_icon = 'images/large/cone.png'
  cmd.menu_text = cmd.tooltip = 'Create cone'
  cmd.status_bar_text = 'Create a cone.'
  toolbar.add_item cmd


  cmd = UI::Command.new('Capsule'){ MSketchyPhysics3.createPrim('capsule') }
  cmd.small_icon = 'images/small/capsule.png'
  cmd.large_icon = 'images/large/capsule.png'
  cmd.menu_text = cmd.tooltip = 'Create a capsule or chamfer'
  cmd.status_bar_text = 'Create a capsule or chamfer.'
  toolbar.add_item cmd


  #~cmd = UI::Command.new('Torus'){ MSketchyPhysics3.createPrim('torus') }
  #~cmd.small_icon = 'images/SketchySolids-Torus.png'
  #~cmd.large_icon = 'images/SketchySolids-Torus.png'
  #~cmd.menu_text = cmd.tooltip = 'Create torus'
  #~cmd.status_bar_text = 'Create a torus.'
  #~toolbar.add_item cmd


  cmd = UI::Command.new('Floor'){ MSketchyPhysics3.createPhysicsFloor }
  cmd.small_icon = 'images/small/floor.png'
  cmd.large_icon = 'images/large/floor.png'
  cmd.menu_text = cmd.tooltip = 'Create floor'
  cmd.status_bar_text = 'Create a static-mesh floor.'
  toolbar.add_item cmd

  toolbar.add_separator

  cmd = UI::Command.new('Wheel'){ MSketchyPhysics3.createPrim('wheel') }
  cmd.small_icon = 'images/small/wheel.png'
  cmd.large_icon = 'images/large/wheel.png'
  cmd.menu_text = cmd.tooltip = 'Create wheel'
  cmd.status_bar_text = 'Create wheel, a capsule with a hinge or servo (press CTRL) at center.'
  toolbar.add_item cmd


  cmd = UI::Command.new('Door'){ MSketchyPhysics3.createPrim('door') }
  cmd.small_icon = 'images/small/door.png'
  cmd.large_icon = 'images/large/door.png'
  cmd.menu_text = cmd.tooltip = 'Create door'
  cmd.status_bar_text = 'Create door, a box with a hinge or servo (press CTRL) at the first corner.'
  toolbar.add_item cmd


  cmd = UI::Command.new('Lift'){ MSketchyPhysics3.createPrim('lift') }
  cmd.small_icon = 'images/small/lift.png'
  cmd.large_icon = 'images/large/lift.png'
  cmd.menu_text = cmd.tooltip = 'Create lift'
  cmd.status_bar_text = 'Create lift, a capsule with a built in slider or piston (press CTRL) at center.'
  toolbar.add_item cmd

  toolbar.show

  file_loaded(__FILE__)
end
