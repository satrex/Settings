require 'Sketchup'
load 'loadpaths.rb'
require 'date'

def simulate_shadow
    model = Sketchup.active_model
    shadowinfo = model.shadow_info
    shadowinfo["DisplayShadows"] = true

  #  shadowinfo["Latitude"] = 36.414099
  #  shadowinfo["Longitude"] = 140.551171

    sunrise = shadowinfo["SunRise_time_t"]
    puts "sunrise = " + DateTime.strptime(sunrise.to_s,'%s').strftime('%m/%d %H:%M')
    sunset = shadowinfo["SunSet_time_t"]
    puts "sunset = " + DateTime.strptime(sunset.to_s,'%s').strftime('%m/%d %H:%M')
    daytime = sunset - sunrise

    puts DateTime.strptime(sunrise.to_s, '%s').strftime('%m/%d %H:%M')
    shadowinfo["ShadowTime_time_t"] = sunrise
    
    11.times { |hour|
      UI.start_timer(3 * hour){
        time =sunrise + (daytime / 10 * hour)
        puts DateTime.strptime(time.to_s, '%s').strftime('%m/%d %H:%M')
        shadowinfo["ShadowTime_time_t"] = time
      }
    }
end

simulate_shadow
