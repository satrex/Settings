# Copyright 2014, Trimble Navigation Limited

# This software is provided as an example of using the Ruby interface
# to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# Initializer for WebTextures Extension.

require 'sketchup.rb'
require 'extensions.rb'
require 'langhandler.rb'

module Sketchup::WebTextures

# Put translation object where the extension can find it.
$wt_strings = LanguageHandler.new("webtextures.strings")

# Load the extension.
wt_extension = SketchupExtension.new($wt_strings.GetString(
  "Photo Textures"), "su_webtextures/webtextures_loader.rb")

wt_extension.description = $wt_strings.GetString("Photo Textures" +
  " allows you to apply textures from online photo sources.")
wt_extension.version = "1.1.2"
wt_extension.creator = "SketchUp"
wt_extension.copyright = "2014, Trimble Navigation Limited"

# Register the extension with Sketchup.
Sketchup.register_extension wt_extension, true

end # module Sketchup::WebTextures
