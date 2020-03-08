#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright 2004, @Last Software, Inc.
# Updated Dec. 2007 by Fredo6

# This software is provided as an example of using the Ruby interface to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name		:   BezierSpline.rb
# Type		:   Sketchup Tool
# Description	:   A tool to create and edit Bezier, Cubic Bezier, Polyline and other mathematical curves.
# Menu Item	:   Draw --> one menu item for each curve type
# Context Menu	:   Edit xxx Curve, Convert to xxx curve
# Usage		:   See Tutorial on  'Bezierspline' in PDF format
# Initial Date	:   10 Dec 2007 (original Bezier.rb 8/26/2004)
# Releases	:   08 Jan 2008 -- fixed some bugs in inference drawing
#			:   17 Oct 2008 -- fixed other bugs, cleanup menu and more flexible on icons
#			:   07 Nov 2010 -- fixed bug for performance menu handler
# Credits	:   CadFather for the toolbar icons
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

require 'sketchup.rb' 
require 'extensions.rb' 

module Bezierspline

@@name = "BezierSpline"
@@version = "1.7c"
folder = "BZ_Dir_17"
@@sdate = "23 Mar 15"
@@creator = "Fredo6"

file__ = __FILE__
file__ = file__.force_encoding("UTF-8") if defined?(Encoding)
file__ = file__.gsub(/\\/, '/')

path = File.join(File.dirname(file__), folder, "bezierspline_main.rb") 
if Sketchup.get_locale == "FR"
	@@description = "Courbes de Bezier et Splines" 
else
	@@description = "Bezier and Splines Curves" 
end	
ext = SketchupExtension.new("BezierSpline", path) 
ext.creator = @@creator 
ext.version = @@version + " - " + @@sdate 
ext.copyright = "Fredo6 - © 2007-2014" 
ext.description = @@description
Sketchup.register_extension ext, true

def Bezierspline.get_name ; @@name ; end
def Bezierspline.get_date ; @@sdate ; end
def Bezierspline.get_version ; @@version ; end

def Bezierspline.register_plugin_for_LibFredo6 
	{	
		:name => @@name,
		:author => @@creator,
		:version => @@version,
		:date => @@sdate,	
		:description => @@description,
		:link_info => "http://sketchucation.com/forums/viewtopic.php?f=323&t=13563#p100509"
	}
end

end #Module Bezierspline


