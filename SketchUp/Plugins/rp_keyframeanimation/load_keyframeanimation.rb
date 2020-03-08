#----------------------------------------------------------------------------#
# Location    :   Plugins/rp_keyframeanimation/load_keyframeanimation.rb
# Description :   Loads all the other files. 
# Date        :   5/27/2013
# Email       :   contact@regularpolygon.org
# Website     :   http://regularpolygon.org/
#----------------------------------------------------------------------------#


module RP
	@@debug = false
	KF_DIRECTORY = File.dirname( __FILE__ )

	def self.debug?; @@debug; end
	def self.debug=(status); @@debug = (status == true); end
end  


Sketchup.require('rp_keyframeanimation/activation_dialog')
Sketchup.require('rp_keyframeanimation/phone_home_dialog')
Sketchup.require('rp_keyframeanimation/license')
Sketchup.require('rp_keyframeanimation/transformations')
Sketchup.require('rp_keyframeanimation/instances')
Sketchup.require('rp_keyframeanimation/observers')
Sketchup.require('rp_keyframeanimation/settings')
Sketchup.require('rp_keyframeanimation/tweens')
Sketchup.require('rp_keyframeanimation/ui')