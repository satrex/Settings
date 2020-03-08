require 'sketchup.rb'


module SketchyReplay

class SKPViewer

    def initialize(dlg)
        @dlg = dlg
    end

    def onViewChanged(v)
        puts v.camera.eye
        puts v.camera.target
        puts @dlg
    end

end # class SKPViewer


class << self

def export_to_kerkythea
  unless defined?(SU2KT)
    UI.messagebox 'Kerkythea (SU2KT) plugin is not installed.'
    return false
  end
  unless SU2KT.respond_to?(:export_sp_animation)
    add_in_script = %q{
def self.export_sp_animation
  SU2KT.reset_global_variables
  model = Sketchup.active_model
  if Sketchup.version.to_i > 6
    model.start_operation('Export SP to Kerkythea', true)
  else
    model.start_operation('Export SP to Kerkythea')
  end
  # Gather animation records.
  animation_object_list = {}
  start_frame = nil
  end_frame = nil
  model.entities.each { |e|
    next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
    samples = e.get_attribute('SPTAKE', 'samples', nil)
    next if samples.nil?
    unless samples.is_a?(Array)
      e.delete_attribute('SPTAKE')
      next
    end
    for i in 0...samples.size
      next unless samples[i]
      start_frame = i unless start_frame
      start_frame = i if i < start_frame
      end_frame = i unless end_frame
      end_frame = i if i > end_frame
    end
    animation_object_list[e] = samples
  }
  # Check if animation record is not empty.
  if animation_object_list.empty?
    UI.messagebox("Nothing to export!")
    return false
  end
  # Get first stage settings.
  return false unless SU2KT.export_options_window
  # Get second stage settings.
  render_set, rend_files = SU2KT.get_render_settings
  settings = SU2KT.get_stored_values
  # If file doesn't exist use the first render setting file that was found.
  settings[6] = File.exist?(settings[6]) ? File.basename(settings[6], '.xml') : render_set[0]
  promts = ['Start Frame', 'End Frame', 'Rate', 'Replay Camera?', 'Animated Lights and Sun?', 'Resolution', 'Render Settings']
  res = %w[Model-Inherited Custom 320x240 640x480 768x576 800x600 1024x768 1280x720 1280x1024 1920x1080].join('|')
  drop_downs = ['', '', '', 'Yes|No', 'Yes|No', res, render_set.join('|')]
  values = [start_frame, end_frame, 1, 'Yes', settings[2], settings[5], settings[6]]
  results = UI.inputbox(promts, values, drop_downs, 'Export Animation Options')
  return false unless results
  # Use custom resolution
  if results[5] == 'Custom'
    data = UI.inputbox(['Width', 'Height'], [800, 600], 'Use Custom Resolution')
    w = data[0].to_i.abs
    w = 1 if w < 1
    w = 10000 if w > 10000
    h = data[1].to_i.abs
    h = 1 if h < 1
    h = 10000 if h > 10000
    results[5] = "#{w}x#{h}"
  end
  # Replace rendering setting with full file path.
  results[6] = rend_files[render_set.index(results[6])]
  # Store new settings.
  settings[2] = results[4]
  settings[5] = results[5]
  settings[6] = results[6]
  SU2KT.store_values(settings)
  # Select export path and create export folder.
  #~ script_file = SU2KT.select_script_path_window
  #~ return false unless script_file
  model_filename = File.basename(model.path)
  if model_filename.empty?
    model_name = 'Untitled.kst'
  else
    model_name = model_filename.split('.')[0..-2].join('.') + '.kst'
  end
  script_file = UI.savepanel('Export Script Path', '', model_name)
  return false unless script_file
  if script_file == script_file.split('.')[0..-2].join('.') # No file extension
    script_file << '.kst'
  end
  @model_name = File.basename(script_file)
  @model_name = @model_name.split('.')[0]
  @frames_path = File.dirname(script_file) + @ds + 'Anim_' + File.basename(script_file).split('.')[0..-2].join('.')
  Dir.mkdir(@frames_path) unless FileTest.exist?(@frames_path)
  @path_textures = File.dirname(script_file)
  # Optimize values.
  temp = start_frame
  start_frame = results[0].to_i.abs
  start_frame = temp if start_frame >= end_frame
  temp = end_frame
  end_frame = results[1].to_i.abs
  end_frame = temp if end_frame <= start_frame || end_frame > temp
  rate = results[2].to_i.abs
  rate = 1 if rate == 0
  anim_camera = (results[3] == 'Yes')
  @anim_sun = (results[4] == 'Yes')
  @export_full_frame = true
  @scene_export = true
  @resolution = (results[5] == 'Model-Inherited') ? '4x4' : results[5]
  @instanced = false
  # Gather final data since we got to the final stage.
  # Get camera record.
  begin
    camera_record = eval(model.get_attribute('SPRECORD', 'Camera', ''))
  rescue Exception => e
    model.attribute_dictionaries.delete('SPRECORD')
    camera_record = {}
  end
  camera_record = {} unless camera_record.is_a?(Hash)
  # Record original transformations.
  orig_transformations = {}
  animation_object_list.keys.each { |e|
    orig_transformations[e] = e.transformation
  }
  # Record original camera.
  camera = model.active_view.camera
  orig_camera = [camera.eye, camera.target, camera.up, camera.fov]
  # Create main XML file.
  out_file = script_file.split('.')[0..-2].join('.') + '.xml'
  out = File.new(out_file, 'w')
  # Export data to the main XML file.
  #SU2KT.export_global_settings(out)
  SU2KT.export_render_settings(out, results[6])
  SU2KT.find_lights(model.entities, Geom::Transformation.new)
  SU2KT.write_sky(out)
  if @instanced
    SU2KT.export_instanced(out, model.entities)
  else
    SU2KT.export_meshes(out, model.entities)
  end
  SU2KT.export_current_view(model.active_view, out)
  SU2KT.export_lights(out) if @export_lights
  SU2KT.write_sun(out)
  SU2KT.finish_close(out)
  # Update merge settings.
  SU2KT.set_merge_settings
  # Create script file.
  script = File.new(script_file, 'w')
  # Make sure it loads the main XML file.
  script.puts "message \"Load #{out_file}\""
  # Export SP animation
  i = start_frame
  count = 1
  while i <= end_frame
    # Display frame
    puts "Please wait! Exporting frame #{i} / #{end_frame}."
    # Set camera position
    if anim_camera && camera_record[i]
      eye, target, up, fov = camera_record[i]
      camera.set(eye, target, up)
      camera.fov = fov
    end
    # Transform entities
    animation_object_list.each { |ent, record|
      next unless record[i]
      ent.move! record[i]
    }
    # Export data to the frame file
    frame_name = sprintf("%06d", count)
    full_path = @frames_path + @ds + frame_name + '.xml'
    script.puts("message \"Merge '#{full_path}' 5 0 4 0 0\"")
    script.puts("message \"Render\"")
    script.puts("message \"SaveImage " + @frames_path + @ds + frame_name + ".jpg\"")
    out = File.new(full_path, 'w')
    SU2KT.export_render_settings(out, settings[6])
    #SU2KT.find_lights(model.entities, Geom::Transformation.new)
    SU2KT.write_sky(out)
    SU2KT.collect_faces(Sketchup.active_model.entities, Geom::Transformation.new)
    SU2KT.export_faces(out)
    SU2KT.export_fm_faces(out)
    SU2KT.export_current_view(model.active_view, out)
    #SU2KT.export_lights(out) if @export_lights
    SU2KT.write_sun(out)
    SU2KT.finish_close(out)
    # Increment counter
    break if i == end_frame
    i += rate
    i = end_frame if i > end_frame
    count += 1
  end
  # Finalize
  orig_transformations.each { |e, tra| e.move! tra }
  eye, target, up, fov = orig_camera
  camera.set(eye, target, up)
  camera.fov = fov
  model.commit_operation
  script.close
  # It is important that textures are exported last!
  SU2KT.write_textures
  msg = "Finished exporting SP animation! Now, you're left to adjust "
  msg << "#{File.basename(out_file)} render settings, run the render script, "
  msg << "and combine final images using a software like Adobe Premierre.\n\n"
  msg << "You may skip adjusting render settings and get to the rendering "
  msg << "right away. Would you like to start rendering right away?"
  result = UI.messagebox(msg, MB_YESNO)
  @export_file = script_file # Used by render_animation as the script path.
  # Render animation.
  if result == IDYES
    kt_path = SU2KT.get_kt_path
    return unless kt_path
    if RUBY_PLATFORM =~ /mswin|mingw/i
      batch_file_path = File.join( File.dirname(kt_path), 'start.bat' )
      batch = File.new(batch_file_path, 'w')
      batch.puts "start \"\" \"#{kt_path}\" \"#{script_file}\""
      batch.close
      UI.openURL(batch_file_path)
    else # MAC solution
      Thread.new do
        script_file_path = File.join( script_file.split(@ds) )
        system(`#{kt_path} "#{script_file_path}"`)
      end
    end
  end
  SU2KT.reset_global_variables
  # Return success
  true
end}
    SU2KT.module_eval(add_in_script)
  end
  SU2KT.export_sp_animation
end


def exportit
    model = Sketchup.active_model
    model.definitions.each { |d|
        if d.instances.length > 0
            model.start_operation('temp')
            model.entities.add_instance(d, Geom::Transformation.new)
            elist = model.entities.to_a
            model.entities.erase_entities(elist)
            model.abort_operation
        end
    }
end

def showit
    dir = File.dirname(__FILE__)
    wdir = File.join(dir, 'o3d')
    fname = File.join(wdir, 'temp.kmz')
    # Note weird ending. Needed to make it work on win.
    outdir = wdir + '/temp\\'
    outname = rand(0xffffffff).to_s + 'temp.tgz'

    Sketchup.active_model.export(fname, false)
    system('del "'+outdir+'*.tgz" ')
    system(wdir+'/converter/o3dconverter.exe "'+fname+'" "'+outdir+outname+'"')

    dlg = UI::WebDialog.new('SPKViewer', true, 'asdfa2342', 739, 641, 640, 480, true)
    dlg.set_file(wdir+'/simpleviewer.html?fname='+outname)
    dlg.set_file(wdir+'/SKPViewer/viewer.html?fname='+outname)
    puts wdir
    dlg.show
    #Sketchup.active_model.active_view.add_observer(SKPViewer.new(dlg))
    dlg
end

def fakeExport
    # Get animation accessors
    sr = SketchyReplay::SketchyReplay.new
    # Check for animation in the file
    return if sr.lastFrame == 0
    # Set objects pos and camera for first frame.
    sr.start
    # Export first frame here
    0.upto(sr.lastFrame){
        # Advance object and camera positions
        sr.nextFrame
        puts sr.frame
        # Export frame here:
    }
    # Cleanup
    sr.rewind
end

end # proxy class


#~ class Array #Array to Hash. Nice! found on codesnipets.com
  #~ def to_h(&block)
    #~ Hash[*self.collect { |v|
      #~ [v, block.call(v)]
    #~ }.flatten]
  #~ end
#~ end


class SketchyReplay

    attr_reader :frame
    attr_reader :lastFrame

    @@activeInstance = nil

    def self.activeInstance
      @@activeInstance
    end

    def initialize
        @frame = 0
        @lastFrame = 0
        @bPaused = false
        @bStopped = true
        @started = false
        @animationObjectList = {}
        @transformations = {}
        @animationRate = 1
        @cameraParent = nil
        @cameraTarget = nil
        @cameraType = nil # type=fixed,relative,drag
        @cam_data = {}
        findAnimationObjects
    end

    def findAnimationObjects
        @animationObjectList.clear
        @lastFrame = 0
        Sketchup.active_model.entities.each { |ent|
            next unless ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
            samples = ent.get_attribute('SPTAKE', 'samples', nil)
            next if samples.nil?
            unless samples.is_a?(Array)
              ent.delete_attribute('SPTAKE')
              next
            end
            @lastFrame = samples.size if samples.size > @lastFrame
            @animationObjectList[ent] = samples if ent.valid?
        }
    end

    def export
        findAnimationObjects
        if @animationObjectList.empty?
            UI.messagebox("Nothing to export!")
            return false
        end
        startFrame = 0
        endFrame = @lastFrame
        rate = @animationRate
        saveType = 'skp'
        prompts = ['Start Frame', 'End Frame', 'Rate', 'Replay Camera?', 'Save As']
        values = [startFrame, endFrame, @animationRate, 'no', saveType]
        types = 'skp|png|jpg'
        results = UI.inputbox(prompts, values, ['', '', '', 'yes|no', 'skp|png|jpg'], 'Export Settings')
        return unless results
        startFrame, endFrame, @animationRate, animCam, saveType = results
        $spReplayCamera = (animCam == 'yes')
        startFrame = startFrame.to_i.abs
        endFrame = endFrame.to_i.abs
        @animationRate = @animationRate.to_i
        @animationRate = 1 if @animationRate.zero?

        model = Sketchup.active_model
        path = model.path
        path = File.basename(path, '.skp')
        sf = UI.savepanel('Export Animation', nil, path)
        return unless sf
        dir = File.dirname(sf)
        fn = File.basename(sf, '.skp')
        dir.gsub!(/\\/,'/') # change \ to /.
        #begin
        #  cam_data = eval(model.get_attribute('SPRECORD', 'Camera', ''))
        #rescue Exception => e
        #  model.attribute_dictionaries.delete('SPRECORD')
        #  cam_data = {}
        #end
        #cam_data = {} unless cam_data.is_a?(Hash)
        model.start_operation 'Export Animation'
        expFrame = 0
        cam = model.active_view.camera
        orig = [cam.eye, cam.target, cam.up, cam.fov]
        begin
            self.start
            # Temporary erase unessential data.
            if saveType == 'skp'
              @animationObjectList.keys.each { |ent|
                ent.attribute_dictionaries.delete('SPTAKE')
              }
              model.attribute_dictionaries.delete('SPRECORD')
              model.definitions.purge_unused
              model.materials.purge_unused
              model.layers.purge_unused
              model.styles.purge_unused
            end
            while(@frame < endFrame)
                nextFrame(nil)
                #if animCam == 'yes' and cam_data[frame]
                #    data = cam_data[frame]
                #    cam.set(data[0], data[1], data[2])
                #    cam.fov = data[3]
                #end
                fname = "#{dir}/#{fn}_%06d.#{saveType}" % expFrame
                if saveType == 'skp'
                    if Sketchup.version.to_i < 14
                        model.save(fname)
                    else
                        if model.path.empty?
                            model.save(fname)
                        else
                            model.save_copy(fname)
                        end
                    end
                else
                    model.active_view.write_image(fname)
                end
                expFrame += 1
            end
            setFrame(0)
        rescue Exception => e
            UI.messagebox("Error: #{e}\n#{e.backtrace[0..2].join("\n")}", MB_OK, 'Error Exporting Animation')
        ensure
            cam.set(orig[0], orig[1], orig[2])
            cam.fov = orig[3]
        end
        model.abort_operation
        true
    end

    def start
        return if @started
        model = Sketchup.active_model
        @bPaused = false
        @bStopped = false
        @transformations.clear
        model.entities.each { |ent|
            if ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
                @transformations[ent.entityID] = ent.transformation
            end
        }
        camera = model.active_view.camera
        @cameraRestore = Sketchup::Camera.new(camera.eye, camera.target, camera.up)
        setCameraToPage(model.pages.selected_page)
        begin
          @cam_data = eval(model.get_attribute('SPRECORD', 'Camera', ''))
        rescue Exception => e
          model.attribute_dictionaries.delete('SPRECORD')
          @cam_data = {}
        end
        @cam_data = {} unless @cam_data.is_a?(Hash)
        findAnimationObjects
        if @animationObjectList.empty?
          @bPaused = true
          @started = false
        else
          @bPaused = false
          @started = true
        end
    end

    # Start the animation
    def play
        @@activeInstance = self
        @animationRate = @animationRate.abs
        @bPaused = !@bPaused
        self.start
        return false if @animationObjectList.empty?
        #Sketchup.active_model.select_tool(@bPaused ? nil : self)
        view = Sketchup.active_model.active_view
        view.animation = @bPaused ? nil : self
        view.show_frame
        true
    end

    def pause
        @bPaused = true
        Sketchup.active_model.active_view.show_frame
    end

    def isPaused
        @bPaused
    end

    def paused?
        @bPaused
    end

    def reverse
        return if @frame <= 0
        @bPaused = false
        @animationRate = -@animationRate
        #Sketchup.active_model.select_tool(self)
        view = Sketchup.active_model.active_view
        view.animation = self
        view.show_frame
    end

    def rewind
        return unless @started
        @@activeInstance = nil
        @started = false
        @bPaused = true
        setCameraToPage(Sketchup.active_model.pages.selected_page)
        cameraPreFrame
        setFrame(0)
        updateCamera()
        @bStopped = true
        if @cameraRestore
            Sketchup.active_model.active_view.camera = @cameraRestore
        end
        @transformations.clear
        @animationObjectList.clear
        @cam_data.clear
        #Sketchup.active_model.select_tool(nil)
        view = Sketchup.active_model.active_view
        view.animation = nil
        view.invalidate
    end

    def setFrame(frameNumber)
        @frame = frameNumber
        #Sketchup.vcb_value = frameNumber
        Sketchup.set_status_text "Frame: #{@frame}", SB_VCB_LABEL
        # If needed find objects.
        findAnimationObjects() if @animationObjectList.empty?
        # Move objects to original placement if frame is zero.
        if @frame == 0
          Sketchup.active_model.entities.each { |ent|
            tra = @transformations[ent.entityID]
            next unless tra
            ent.move! tra
          }
          return
        end
        # Move objects to desired positions.
        @animationObjectList.each { |ent, data|
            next unless ent.valid?
            tra = data[@frame]
            next unless tra.is_a?(Array)
            ent.move! Geom::Transformation.new(tra)
        }
    end

    def nextFrame(view = nil)
        self.start
        unless @bPaused
            @frame += @animationRate
            cameraPreFrame()
            setFrame(@frame)
            updateCamera()
            if $spReplayCamera && @cam_data[@frame]
              data = @cam_data[@frame]
              cam = Sketchup.active_model.active_view.camera
              cam.set(data[0], data[1], data[2])
              cam.fov = data[3]
            end
            view.show_frame if view
            Sketchup.set_status_text "Frame #{@frame} / #{@lastFrame}"
        end
        true
    end

    def findComponentNamed(name)
        return unless name.is_a?(String)
        return if name.empty?
        Sketchup.active_model.definitions.each { |cd|
            cd.instances.each { |ci|
                return ci if ci.name.casecmp(name) == 0
            }
        }
        nil
    end

    #camera follow, target, whatever.
    #duration
    #start frame, end frame.
    #next/prev frame name (optional for out of sequence cuts.

    def findPageNamed(name)
        return unless name.is_a?(String)
        Sketchup.active_model.pages.each { |p|
            return p if p.name.casecmp(name) == 0
        }
        nil
    end

    def setCameraToPage(page)
        return unless $spMovieMode
        @cameraParent = nil
        @cameraTarget = nil
        @cameraType = nil
        @cameraNextPage = nil
        @cameraFrameEnd = nil
        return unless page
        #Sketchup.active_model.pages.selected_page.description.downcase.gsub(/ /, '').split(';')
        paramArray = page.description.downcase.gsub(/ /, '').split(';')
        params = Hash[*paramArray.collect { |v|
            [v.split('=')[0], v.split('=')[1]]
        }.flatten]
        # if series
        # find right page in series
        # set transition frame and next page
        @cameraParent = findComponentNamed(params['parent']) # follow
        @cameraTarget = findComponentNamed(params['target']) # track

        #@cameraParent = findComponentNamed(params['follow']) # follow
        #@cameraTarget = findComponentNamed(params['track']) # track

        @cameraType = params['type']
        @cameraNextPage = findPageNamed(params['nextpage'])

        # Defaults to first (0) and last frame in animation
        @cameraEndFrame = params['endframe']
        @cameraStartFrame = params['startFrame']

        @frame = params['setframe'].to_i if params['setframe']
        @pauseFrame = params['pauseframe'] ? params['pauseframe'].to_i : nil
        @animationRate = params['animationrate'] ? params['animationrate'].to_i : 1
        #print @cameraNextPage, ',', @cameraEndFrame.to_i
        Sketchup.active_model.active_view.camera = page.camera
    end

    def onUserText(text, view)
        puts "onUserText: #{text}"
    end

    def findCameras
        @cameraEntity = nil
        @cameraTargetEntity = nil
        @cameraPreMoveOffset = nil
        begin
            params = Sketchup.active_model.pages.selected_page.description.downcase.split(';')
            if pageDesc.include?('parent=')
                pageDesc.chomp!
                targetname = pageDesc.split('=')[1]
                Sketchup.active_model.entities.each { |ent|
                    if ent.typename.downcase == 'componentinstance' and ent.name.downcase == targetname
                        @cameraTargetEntity = ent
                        camera = Sketchup.active_model.active_view.camera
                    end
                }
            end
        rescue Exception => e
            puts "Error finding cameras:\n#{e}\n#{e.backtrace[0..2].join("\n")}"
        end
    end

    def cameraPreFrame
        if @cameraEndFrame != nil and @frame > @cameraEndFrame.to_i and @cameraNextPage != nil
            setCameraToPage(@cameraNextPage)
        end
        if @pauseFrame != nil and @frame > @pauseFrame.to_i
            self.pause
        end
        if @frame > @lastFrame and @animationObjectList.size > 0
            @frame = @lastFrame
            self.pause
        end
        if @animationRate < 0 and @frame < 0
            @frame = 0
            self.reverse
            self.pause
        end
        if @cameraParent
            #@cameraPreMoveOffset = Sketchup.active_model.active_view.camera.eye-@cameraParent.transformation.origin
            @cameraPreMoveOffset = Sketchup.active_model.active_view.camera.eye - @cameraParent.bounds.center
        end
    end

    def calcPointAlongCurve(curve, percent)
        curve = Sketchup.active_model.selection.first.curve
        totalLength = 0
        curve.edges.each { |e|
            totalLength += e.length
        }
        dist = (1.0/totalLength)*percent
        curve.edges.each { |e|
            dist = dist-e.length
            if dist < 0
                return e.line[0]+(e.line[1].length=(e.length-dist))
            end
        }
    end

    def updateCamera
        #Sketchup.active_model.selection.first.curve.vertices.each { |v| print v.position }
        #Sketchup.active_model.selection.first.curve.vertices[curVert].each { |v| print v.position }
        camera = Sketchup.active_model.active_view.camera
        if @cameraParent
            #if @cameraParent.description.downcase.include?('animationpath')
            #   dest = calcPointAlongCurve(@cameraPath, 1.0/(frameEnd-frameStart)) + @cameraPreMoveOffset
            #else
                #dest = @cameraParent.transformation.origin + @cameraPreMoveOffset
                dest = @cameraParent.bounds.center + @cameraPreMoveOffset
            #end
            camera.set(dest, dest+camera.direction, Z_AXIS)
        end
        if @cameraTarget
            target = @cameraTarget
            camera.set(camera.eye, @cameraTarget.bounds.center, Z_AXIS)
        end
    end

    # The stop method will be called when SketchUp wants an animation to stop
    # this method is optional.
    def stop
    end

    ############################## Start of Tool ###################################

    # The activate method is called when a tool is first activated.  It is not
    # required, but it is a good place to initialize stuff.
    def activate
      model = Sketchup.active_model
      if Sketchup.version.to_i > 6
        model.start_operation('Sketchy Replay', true)
      else
        model.start_operation('Sketchy Replay')
      end
      model.active_view.animation = self
    end

    def deactivate(view)
      Sketchup.active_model.commit_operation
      view.animation = nil
    end

    def onLButtonDown(flags, x, y, view)
    end

    def getExtents
        bb = Sketchup.active_model.bounds
        if Sketchup.version.to_i > 6
            Sketchup.active_model.entities.each { |ent|
                bb.add(ent.bounds)
            }
        end
        bb
    end

    # onLButtonUp is called when the user releases the left mouse button
    def onLButtonUp(flags, x, y, view)
    end

    # draw is optional.  It is called on the active tool whenever SketchUp
    # needs to update the screen.
    #def draw(view)
    #end

    #def onSetCursor()
    #end

    ############################## End of Tool ###################################

end # class SketchyReplay
end # module SketchyReplay
