=begin
Copyright 2014 (c)
All Rights Reserved
THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE.
Author: Gabor Pupp & TIG
Organization:  SketchUcation LLC
Name: myShortcuts
Version: 0.3.1
SU Version: >= 8.0 and up
Date: 2014 04
Description: Displays the SketchUp shortcuts in a webdialog
Usage: Plugins > SketchUcation > My Shortcuts...
=end

UI.start_timer(0.025, false){ # wait for SUBMENU to be defined
	if defined?(Encoding)
		me=File.basename(__FILE__).force_encoding("UTF-8")
	else	
		me=File.basename(__FILE__)
	end
	unless file_loaded?(me)
		if defined?(SCF::SUBMENU)
			SCF::SUBMENU.add_item('My Shortcuts...'){ SCF.myShortcuts() }
		else
			UI.menu("Plugins").add_item('My Shortcuts...'){ SCF.myShortcuts() }
		end
		file_loaded(me)
	end
}

module SCF
	
	def self.myShortcuts()
		begin
			SCFapi.log_write("myShortcuts-Run")
		rescue
		end
		dlg = UI::WebDialog.new("My Shortcuts", true, "My Shortcuts", 739, 641, 150, 150, true)
		dlg.set_url("http://jroot.sketchucation.com/shortcutter/shortcutter_0_3_0.html")
		dlg.allow_actions_from_host("sketchucation.com")
		dlg.allow_actions_from_host("jroot.sketchucation.com")
		dlg.add_action_callback("shortcutter"){|d, p|
			if IS_MAC
				txt	= IO.read(File.join(File.dirname(Sketchup.find_support_file("Plugins")), "Shortcuts.plist"))
				txt.gsub!(/[>] [<]/, '>Space<')
				txt.gsub!(/[>]0[<]/, '><')
				txt.gsub!(/#{"\t"}/, '')
				txt.gsub!(/#{"\n"}/, '')
				txt=txt.split("<array><string>")[1]
				txt=txt.split("</string></array>")[0]
				txt.gsub!(/[>]131072[<]/, ">Ashift<")
				txt.gsub!(/[>]262144[<]/, ">Ctl<")
				txt.gsub!(/[>]393216[<]/, ">Ctl+Ashift<")
				txt.gsub!(/[>]524288[<]/, ">Opt<")
				txt.gsub!(/[>]655360[<]/, ">Opt+Ashift<")
				txt.gsub!(/[>]786432[<]/, ">Ctl+Opt<")
				txt.gsub!(/[>]917504[<]/, ">Ctl+Opt+Ashift<")
				txt.gsub!(/[<]\/string[>][<]integer[>]/, "+++")
				txt.gsub!(/[<]\/integer[>][<]string[>]/, "\t")
				txt.gsub!(/[+][+][+]#{"\t"}/, "\t")
				txa=txt.split("</string><string>")
				txa.dup.each_with_index{|e, i|
					km=e.split("\t")[0]
					km=km.upcase if km=~/^[a-z]$/
					cm=e.split("\t")[1]
					if km =~ /[+][+][+]/
						kk=km.split("+++")
						kk[0]=kk[0].upcase if kk[0]=~/^[a-z]$/
						km=kk.reverse.join("+")
					end
					txa[i] = km+"\t"+cm
				}
				myscuts = txa.sort.join("\\n")
				myscuts.gsub!(/#{"\t/"}/, "\t")
				h={}
				h["selectOrbitTool:"]="Camera/Orbit"
				h["selectDollyTool:"]="Camera/Pan"
				h["selectZoomTool:"]="Camera/Zoom"
				h["viewZoomExtents:"]="Camera/Zoom Extents"
				h["makeComponent:"]="Edit/Make Component..."
				h["selectSelectionTool:"]="Tools/Select"
				h["selectMeasureTool:"]="Tools/Tape Measure"
				h["selectPaintTool:"]="Tools/Paint Bucket"
				h["selectPushPullTool:"]="Tools/Push/Pull"
				h["selectMoveTool:"]="Tools/Move"
				h["selectRotateTool:"]="Tools/Rotate"
				h["selectScaleTool:"]="Tools/Scale"
				h["selectOffsetTool:"]="Tools/Offset"
				h["selectEraseTool:"]="Tool/Eraser"
				h["toggleDisplayBackEdges:"]="View/Edge Style/Back Edges"
				if Sketchup.version.to_i < 14
					h["selectLineTool:"]="Draw/Line"
					h["selectRectangleTool:"]="Draw/Rectangle"
					h["selectCircleTool:"]="Draw/Circle"
					h["selectArcTool:"]="Draw/Arc"
				else
					h["selectLineTool:"]="Draw/Lines/Line"
					h["selectRectangleTool:"]="Draw/Shapes/Rectangle"
					h["selectCircleTool:"]="Draw/Shapes/Circle"
					h["selectArcTool:"]="Draw/Arcs/Arc"
				end
				h.each{|a| myscuts.gsub!(/#{a[0]}/, a[1]) }
				myscuts = myscuts.split("\\n")
				myscuts.each_with_index{|e, i|
					if e =~ /[:]$/
						a = e.split("\t")
						myscuts[i]="#{a[0]}\tOther/#{a[1]}"
					end
				}
				myscuts = myscuts.join("\\n")
			else # PC
				myscuts = Sketchup.get_shortcuts.sort.join("\\n")
			end
			jscript = "shortcutterReturned(\"#{myscuts}\");"
			dlg.execute_script(jscript)
		}
		if IS_MAC
			dlg.show_modal{}
		else
			dlg.show{}
		end
	end
	
end 

