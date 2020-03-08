=begin
Copyright 2014 TIG & SketchUcation LLC (c)  
All rights reserved.  
THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,  
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND  
FITNESS FOR A PARTICULAR PURPOSE.  

Usage:  

This file belongs in the SketchUcation subfolder, 
found within the main default Plugins folder...

Plugins > SketchUcation > 'sketchUcloud...' submenu:  

NOTE:
This RB file should always be put into the 'SketchUcation' subfolder OR within 
the default 'Plugins' folder so that it will Autoload.***
It can NEVER be within the ../sketchUcloud/plugins folder, as it would then not 
Autoload and therefore be unable to bootstrap itself !
***If the 'SketchUcation' subfolder is within the ../sketchUcloud/plugins folder 
then you must place this RB directly within the default 'Plugins' folder, OR 
perhaps in another custom Plugins folder, which you may have added with a tool 
like Fredo's AdditionalPluginsFolders, and which you know will Autoload...
The submenu may appear directly under the 'Plugins' menu IF for some reason 
the SketchUcation toolset has Autoloaded from another location after this RB has 
Autoloaded.

Items:

"Setup My ../sketchUcloud/plugins folder"  

This lets you create the 'C:/Users/UserName/sketchUcloud' folder 
and also its 'plugins' subfolder, if they do not already exist.
It is added to $LOAD_PATH [aka $:].
It also Autoloads that subfolder's contents, and it is set 'Enabled'.
It is also used to 're-Enable' Autoloading if the tool has been 'Disabled'.


"Disable My ../sketchUcloud/plugins folder"

This stops the Autoloading of the 'plugins' subfolder, after SketchUp restarts.
To re-Enable it use 'Setup...'


"Open My ../sketchUcloud/plugins folder"

This opens that 'plugins' subfolder for you...


"Open My http://cloud.sketchucation.com"

This opens your synced page in a browser...

Version:  
1.0	20140626 First issue.  
1.1 20140626 Second issue.
1.2 20140627 Third issue.
=end

module SUC
	### menu
	if defined?(Encoding)
		ME=__FILE__.force_encoding("UTF-8").tr("\\","/")
	else	
		ME=__FILE__.tr("\\","/")
	end
	@is_enabled='false'
	SUCHOME=File.expand_path( (begin;ENV['HOME'].dup.force_encoding('UTF-8');rescue;ENV['HOME'];end) || (begin;ENV['HOMEPATH'].dup.force_encoding('UTF-8');rescue;ENV['HOMEPATH'];end) || (begin;ENV['HOMEDRIVE'].dup.force_encoding('UTF-8');rescue;ENV['HOMEDRIVE'];end) )
	SUCFOLDER=File.join(SUCHOME, "sketchUcloud")
	SUCPLUGINS=File.join(SUCFOLDER, "plugins")
	plugins=Sketchup.find_support_file("Plugins")
	if File.dirname(ME)==SUCPLUGINS || File.dirname(ME)==File.join(SUCPLUGINS, "SketchUcation")
		UI.messagebox("#{ME}\n\nThis is NOT a suitable location for this file.\n\nIt should be Autoloading from within the 'SketchUcation' subfolder inside the default Plugins folder:\n\n#{plugins}\n\nor a similar location; it could also be put directly inside the default Plugins folder.")
		safe=false
	else
		safe=true
	end
	###	
	#UI.messagebox("!!!#{SCFapi.cloud?}")
	@cloud = SCFapi.cloud?
	###
	UI.start_timer(0.025, false){
		if @cloud
			unless file_loaded?(ME) || safe==false
				if defined?(SCF::SUBMENU)
					sm=SCF::SUBMENU.add_submenu("sketchUcloud...")
				else
					sm=UI.menu("Plugins").add_submenu("sketchUcloud...")
				end
				sm.add_item("Setup My ../sketchUcloud/plugins folder"){ self.setup() }
				sm.add_item("Disable My ../sketchUcloud/plugins folder"){ self.disable() }
				sm.add_item("Open My ../sketchUcloud/plugins folder"){ self.open() }
				sm.add_item("Open My http://cloud.sketchucation.com"){ self.cloud() }
				file_loaded(ME)
				SCFapi.log_write("skecthUcloud-loaded?true")
			else
				SCFapi.log_write("skecthUcloud-loaded?false|safe?=#{safe}")
			end
		end
		###
		if safe==true
			begin
				if File.exist?(SUCPLUGINS)
					@is_enabled=Sketchup.read_default('SUC', 'enabled', 'true')
					Sketchup.write_default('SUC', 'enabled', @is_enabled)
					$: << SUCPLUGINS
					$:.uniq!
					Dir.entries(SUCPLUGINS).each{|f|
						next unless File.extname(f).downcase=='.rb' || File.extname(f).downcase=='.rbs'
						Sketchup::require(File.join(SUCPLUGINS, f))
					} if @is_enabled=='true'
					
				else
					@is_enabled='false'
					Sketchup.write_default('SUC', 'enabled', @is_enabled)
				end
			rescue
			end
			SCFapi.log_write("skecthUcloud-is_enabled?#{@is_enabled}")
		end
	}
	###
    def self.setup()
		if @is_enabled=='true' && @cloud
			UI.messagebox("The ../sketchUcloud/plugins folder is already Enabled and Loaded.\n\nWhenever SketchUp starts it will Autoload this folder's contents.\n\nTo Disable this use 'Disable...' and restart SketchUp...\n\nYour \"#{SUCFOLDER}\" folder must be included in your 'sketchUcloud' setup to enable syncing of this 'plugins' folder's contents...")
			SCFapi.log_write("skecthUcloud-setup?repeat")
		else
			begin
				Dir.mkdir(SUCFOLDER)
			rescue
			end
			begin
				Dir.mkdir(SUCPLUGINS)
			rescue
			end
			if @cloud
				begin
					$: << SUCPLUGINS
					$:.uniq!
					@is_enabled='true'
					Sketchup.write_default('SUC', 'enabled', @is_enabled)
					Dir.entries(SUCPLUGINS).each{|f|
						next unless File.extname(f).downcase=='.rb' || File.extname(f).downcase=='.rbs'
						Sketchup::require(File.join(SUCPLUGINS, f))
					}
					UI.messagebox("The ../sketchUcloud/plugins folder is now Enabled and Loaded.\n\nWhenever SketchUp starts it will Autoload this folder's contents.\n\nTo Disable this use 'Disable...' and restart SketchUp...\n\nYour \"#{SUCFOLDER}\" folder must be included in your 'sketchUcloud' setup to enable syncing of this 'plugins' folder's contents...")
					SCFapi.log_write("skecthUcloud-enable?true")
				rescue
				end
			else ### make folder BUT prevent its use !
				@is_enabled=='false'
				Sketchup.write_default('SUC', 'enabled', @is_enabled)
				UI.messagebox("You are NOT registered at SketchUcation.com as a 'sketchUcloud' user.\nTherefore the contents of your folder\n\"#{SUCFOLDER}\"\nwill NOT be synced, and it will NOT be available to receive Install/Update through the PluginStore dialog...")
			end
			SCFapi.log_write("skecthUcloud-cloud?#{@cloud}")
		end
		return
    end
    ###
	def self.disable()
		if @is_enabled=='false'
			UI.messagebox("The ../sketchUcloud/plugins folder is already Disabled !\n\nWhen SketchUp restarts it will NOT Autoload this folder.\n\nTo Re-Enable its AutoLoad use 'Setup...'\n\nIf your \"#{SUCFOLDER}\" folder is included in your 'sketchUcloud' setup, then this Disabling will NOT stop the syncing of 'plugins', BUT that folder's contents will no longer Autoload...")
			SCFapi.log_write("skecthUcloud-disable?repeat")
		else
			Sketchup.write_default('SUC', 'enabled', 'false')
			@is_enabled='false'
			UI.messagebox("The ../sketchUcloud/plugins folder is now Disabled.\n\nWhen SketchUp restarts it will NOT Autoload this folder.\n\nTo Re-Enable its AutoLoad use 'Setup...'\n\nIf your \"#{SUCFOLDER}\" folder is included in your 'sketchUcloud' setup, then this Disabling will NOT stop the syncing of 'plugins', BUT that folder's contents will no longer Autoload...")
			SCFapi.log_write("skecthUcloud-disable?true")
		end
		return
	end
	###
    def self.open()
		UI.openURL("file:///#{SUCPLUGINS}")
		SCFapi.log_write("skecthUcloud-open?file:///#{SUCPLUGINS}")
    end
	###
    def self.cloud()
		UI.openURL("http://cloud.sketchucation.com")
		SCFapi.log_write("skecthUcloud-openURL?http://cloud.sketchucation.com")
    end
	###
	def self.is_enabled()
		return true if @is_enabled=='true'
		return false
	end
	###
end
	