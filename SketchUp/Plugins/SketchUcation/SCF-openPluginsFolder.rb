require('sketchup.rb')
UI.start_timer(0.015, false){ # wait for SUBMENU to be defined
	module SCF
		if defined?(Encoding)
			me=File.basename(__FILE__).force_encoding("UTF-8")
		else	
			me=File.basename(__FILE__)
		end
		unless file_loaded?(me)
			if defined?(SCF::SUBMENU)
				SCF::SUBMENU.add_item('Open Plugins Folder...'){self.openPluginsFolder()}
			else
				UI.menu("Plugins").add_item('Open Plugins Folder...'){self.openPluginsFolder()}
			end
		end
		file_loaded(me)
		def self.openPluginsFolder()
			UI.openURL("file:///#{Sketchup.find_support_file('Plugins')}")
			begin
				SCFapi.log_write("openPluginsFolder-Run?file:///#{Sketchup.find_support_file('Plugins')}")
			rescue
			end
		end
	end
}
