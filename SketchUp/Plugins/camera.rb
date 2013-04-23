require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'
$exStrings = LanguageHandler.new("Examples.strings")
examplesExtension = SketchupExtension.new $exStrings.GetString("Ruby Script Deployment"), "/Library/Application Support/Google SketchUp 8/SketchUp/Plugins//deploy/camera.rb"
examplesExtension.description=$exStrings.GetString("Adds examples of tools created in Ruby to the SketchUp interface.  The example tools are Draw->Box, Plugins->Cost and Camera->Animations.")
Sketchup.register_extension examplesExtension, false
examplesExtension.check
