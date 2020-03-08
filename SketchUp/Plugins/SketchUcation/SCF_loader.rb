=begin
(c) SketchUcation [SCF] / TIG 2014
###
All rights reserved.
THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES; 
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE.
###
SCF_loader.rb
Loads SketchUcation tools from their subfolder.
=end
###
### Load Dialog first
Sketchup::load(File.join(SCF::FOLDER, "SCF_Dialog"))
###
### load all other scripts...
Dir.entries(SCF::FOLDER).each{|r|
	if defined?(Encoding)
		me=File.basename(__FILE__).force_encoding("UTF-8")
	else	
		me=File.basename(__FILE__)
	end
	next if r == File.basename(me) # ignore myself
	next if r =~ /^SCF_Dialog.rb/ ### loaded first
	x = File.extname(r).downcase
	File.delete(File.join(SCF::FOLDER, r)) if x == '.rbx' || x == '.rbsx' ### remove uninstalled files
	next unless x == '.rb' || x == '.rbs'
	Sketchup::load(File.join(SCF::FOLDER, r)) ### load it
}
###
module SCF
	if defined?(Encoding)
		me=File.basename(__FILE__).force_encoding("UTF-8")
	else	
		me=File.basename(__FILE__)
	end
	unless file_loaded?(me)
		###
		SUBMENU = UI.menu("Plugins").add_submenu(LNAME)
		TOOLBAR = UI::Toolbar.new(DESC)
		### Make store cmds
		cmd = UI::Command.new(DESC){SCF_Dialog.new()}
		cmd.tooltip = "#{DESC}"
		cmd.status_bar_text = "#{SBT}"
		cmd.small_icon = File.join(IMAGES, 'SCF-16.png')
		cmd.large_icon = File.join(IMAGES, 'SCF-24.png')
		###
		SUBMENU.add_item(cmd)
		TOOLBAR.add_item(cmd)
		### Make plugins manager cmds
		cmd = UI::Command.new(MDESC){SCFmanager.new()}
		cmd.tooltip = "#{MDESC}"
		cmd.status_bar_text = "#{MSBT}"
		cmd.small_icon = File.join(IMAGES, 'SCFm-16.png')
		cmd.large_icon = File.join(IMAGES, 'SCFm-24.png')
		###
		SUBMENU.add_item(cmd)
		TOOLBAR.add_item(cmd)
		### Make extensions manager cmds
		cmd = UI::Command.new(XDESC){SCFmanagerX.new()}
		cmd.tooltip = "#{XDESC}"
		cmd.status_bar_text = "#{XSBT}"
		cmd.small_icon = File.join(IMAGES, 'SCFx-16.png')
		cmd.large_icon = File.join(IMAGES, 'SCFx-24.png')
		###
		SUBMENU.add_item(cmd)
		TOOLBAR.add_item(cmd)
		### Make install_archive to custom-plugins
		cmd = UI::Command.new(CDESC){RBZtool.archiveInstaller()}
		cmd.tooltip = "#{CDESC}"
		cmd.status_bar_text = "..."
		###
		SUBMENU.add_item(cmd)
		### Make plugin uninstaller
		cmd = UI::Command.new(UDESC){SCFuninstaller.new()}
		cmd.tooltip = "#{UDESC}"
		cmd.status_bar_text = "..."
		###
		SUBMENU.add_item(cmd)
		###
		SUBMENU.add_item("#{TOOLBARTOGGLE}"){(TOOLBAR.visible?) ? TOOLBAR.hide : TOOLBAR.show}
		###
		TOOLBAR.show if TOOLBAR.get_last_state.abs == 1 # TB_VISIBLE/NEVER
		###
	end#unless
	file_loaded(me)
	###
	@model=Sketchup.active_model
	@defns=@model.definitions
	### remove rogue files from v1.1.1
	Dir.entries(PLUGINS).each{|f|
		File.delete(File.join(PLUGINS, f)) if f =~ /^SketchUcationTools-v1-1-1.rbz/
	}
	###
end#module
###
