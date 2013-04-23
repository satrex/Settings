require 'Sketchup'

def simulate_shadow
    model = Sketchup.active_model
    
    shadowinfo = model.shadow_info
    shadowinfo["DisplayShadows"] = true

  #  shadowinfo["Latitude"] = 36.414099
  #  shadowinfo["Longitude"] = 140.551171

    sunrise = shadowinfo["SunRise_time_t"]
    puts "sunrise = " + shadowinfo["SunRise"].strftime('%m/%d %X')
    sunset = shadowinfo["SunSet_time_t"]
    puts "sunset = " + shadowinfo["SunSet"].strftime('%m/%d %X')
    daytime = sunset - sunrise

    shadowinfo["ShadowTime_time_t"] = sunrise
    $hours = [sunrise]
    
    10.times { |hour|
      time = sunrise + (daytime / 10 * hour)
        
      $hours.push(time)
      puts shadowinfo["ShadowTime"].strftime('%m/%d %X')
    }
    $hours.push(sunset)
    $hourIdx = 0;
    show_dialog
end

def show_dialog
 dlg = UI::WebDialog.new("Shadow Inspection", false,
   "ShadowInspector", 200, 150, 150, 150, true);
  html = <<-HTML
  <html>
  <head>
  <script type="text/javascript">
  <!--
    function prevHour(){
       window.location.href="skp:prevHour";
        }

    function nextHour(){
       window.location.href="skp:nextHour";
        }

    function walkThrough(){
       window.location.href="skp:walkThrough";
        }

    function getInterval(){
        return document.getElementById('interval').getAttribute('value');
        }
    -->
    </script>
</head>
<body>
    <form>
      Interval:<input id="interval" style="width:30px;" value="3"></input>sec
      <input type="button" id="walk" onClick="walkThrough()" style="height:10px; position:20, 10 ; width:60;" value="start">
      </br>
      <input type="button" id="prev" onClick="prevHour()" style="height:10px; width:10px; position:20, 10;" value="&lt;">
      <input type="button" id="next" onClick="nextHour()" style="height:10px; width:10px; position:120, 10;" value="&gt;">
    </form>
    </html>
  HTML
  
  dlg.set_html html

  dlg.add_action_callback("nextHour") {|dialog, params|
    model = Sketchup.active_model
    shadowinfo = model.shadow_info
    if($hours[$hourIdx + 1] != nil) then  
        $hourIdx = $hourIdx + 1
        shadowinfo["ShadowTime_time_t"] = $hours[$hourIdx]
    end
  }

  dlg.add_action_callback("prevHour") {|dialog, params|
    model = Sketchup.active_model
    shadowinfo = model.shadow_info
    if($hours[$hourIdx - 1] != nil) then  
        $hourIdx = $hourIdx - 1
        shadowinfo["ShadowTime_time_t"] = $hours[$hourIdx]
    end
  }

  dlg.add_action_callback("walkThrough") {|dialog, params|
    model = Sketchup.active_model
    shadowinfo = model.shadow_info
    $hourIdx = 0 
    puts "started"
    
    interval = dialog.get_element_value("interval").to_i
    11.times { |hour|
      UI.start_timer(interval * hour){
        $hourIdx = $hourIdx + 1
        shadowinfo["ShadowTime_time_t"] = $hours[$hourIdx]
        puts shadowinfo["ShadowTime"].strftime('%m/%d %X')
      }
    }
  }
  
  dlg.show
end
 plugins_menu = UI.menu("Plugins") 
 item = plugins_menu.add_item("inspect_shadow") { simulate_shadow }
 file_loaded(__FILE__)
