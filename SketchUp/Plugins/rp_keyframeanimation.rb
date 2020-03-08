#----------------------------------------------------------------------------#
# Location    :   Plugins/rp_keyframeanimation.rb
# Description :   A SketchupExtension class for Keyframe Animation.
# Date        :   10/19/2014
# Email       :   regular.polygon@gmail.com
# Website     :   http://regularpolygon.org/
#----------------------------------------------------------------------------#


require 'sketchup.rb'
require 'extensions.rb'


module RP
	KF_VERSION = '1.9.2'
end


extension = SketchupExtension.new 'Keyframe Animation', 'rp_keyframeanimation/load_keyframeanimation.rb'
extension.description = "Animate your SketchUp model by adding movement to any object."
extension.version = RP::KF_VERSION
extension.creator = 'Regular Polygon'
extension.copyright = "Regular Polygon copyright #{ Time.now.year }"

Sketchup.register_extension extension, true  # show on 1st install