require 'sketchup.rb'

module MSketchyPhysics3

  @control_sliders = {}
  @control_panel_dialog = nil
  JointControllerStruct = Struct.new(:name, :value, :min, :max)

  class << self

    def control_sliders
      @control_sliders
    end

    def control_panel_dialog
      @control_panel_dialog
    end

    def showControlPanel
      unless @control_panel_dialog
        @control_panel_dialog = UI::WebDialog.new('SP Control Panel', true, 'SPControlPanel', 400, 200, 400, 400, true)
      else
        updateControllerSliders()
      end

      dir = File.dirname(__FILE__)
      @control_panel_dialog.set_file( File.join(dir, 'html/control_panel.html') )
      @control_panel_dialog.show {
        updateControllerSliders
      }
      @control_panel_dialog.set_on_close { @control_panel_dialog = nil }
      @control_panel_dialog.add_action_callback('puts') { |d,p| puts p }
      @control_panel_dialog.add_action_callback('setSliderValue') { |d,p|
        key = p.split("=")[0]
        value = p.split("=")[1].to_s.to_f
        @control_sliders[key].value=value;
      }
    end

    def closeControlPanel
      @control_panel_dialog.close if @control_panel_dialog
      @control_panel_dialog = nil
    end

    def escapeHTML(str)
      # puts str.class if $debug
      str = str.to_s
      str.gsub(/&/n, '&amp;').gsub(/\"/n, '&quot;').gsub(/>/n, '&gt;').gsub(/</n, '&lt;').gsub(/\n/n,"\\n").gsub(/\r/n,"").gsub("_", '&#95;').gsub(/\$/n,'&#36;').gsub(/ /n, '&nbsp;')#.gsub("'", '&#39;').gsub("\r", '\r').gsub("\n", '\n')
    end

    def logPhysicsMessage(str)
      return unless @control_panel_dialog
      java = 'el=document.getElementById("log");el.value+="'+ MSketchyPhysics3::escapeHTML(str)+'\n";'
      java += 'el.scrollTop = el.scrollHeight;'
      @control_panel_dialog.execute_script(java)
    end

    def updateControllerSliders
      return unless @control_panel_dialog
      @control_panel_dialog.execute_script("while(controlSlidersTable.rows.length>0){controlSlidersTable.deleteRow(0);}")
      @control_sliders.each { | k,jc |
        key = jc.name
        value = jc.value
        min = jc.min
        max = jc.max
        html = "<div class='carpe_horizontal_slider_track'> "
        html += "<div class='carpe_slider_slit' ></div> "
        html += "<div class='carpe_slider' id='#{key}_slider' distance='140' display='#{key}' style='left:70px;'></div> "
        html += "</div> "
        #html += "<input id='#{key}' type='text' class='carpe_slider_display' value='#{value}' from='#{min}' to='#{max}' decimals='2'/> "

        java = "row = document.getElementById('controlSlidersTable').tBodies[0].insertRow(-1);"
        java += 'row.insertCell(0).innerHTML="'+key+'";'
        java += 'row.insertCell(1).innerHTML="'+html+'";'

        html = "<input id='#{key}' type='text' class='carpe_slider_display' value='#{value}' from='#{min}' to='#{max}' decimals='2'/> "
        java += 'row.insertCell(1).innerHTML="'+html+'";'
        # html = "<button id='#{key}'/> "
        # java += 'row.insertCell(1).innerHTML="'+html+'";'
        @control_panel_dialog.execute_script(java)
      }
      java = 'setupSliders();'
      @control_panel_dialog.execute_script(java)
    end

    def initJointControllers
      @control_sliders.clear
    end

    def createController(name, value, min, max)
      return if @control_sliders[name]
      MSketchyPhysics3.control_sliders[name] = JointControllerStruct.new(name, value, min, max)
      updateControllerSliders
    end

  end # proxy class
end # module MSketchyPhysics3
