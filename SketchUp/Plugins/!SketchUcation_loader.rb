=begin
(c) SketchUcation [SCF] / TIG 2014
###
All rights reserved.
THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES; 
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE.
###
!SketchUcation_loader.rb
Sets up SCF_loader in SketchUcation subfolder.
=end
###
require('sketchup.rb')
require('extensions.rb')
###
module SCF
	###
	### set Constants
	###
	VERSION="2.6.1"
	###
	SCFURL="http://pluginstore.sketchucation.com/pluginstore_2_6_1.php"
	###
	NAME="SCF"
	LNAME="SketchUcation"
	###
	if defined?(Encoding)
		PLUGINS=File.dirname(__FILE__).force_encoding("UTF-8") ### v2014 lashup
	else
		PLUGINS=File.dirname(__FILE__)
	end
    CONTAINER=File.dirname(PLUGINS) ### typically Plugins
    FOLDER=File.join(PLUGINS, LNAME)
	### set up other folders
 	STRINGS=File.join(FOLDER, "Strings") ### Translations
	IMAGES=File.join(FOLDER, "Images") ### Icons
    DATA=File.join(FOLDER, "Data") ### HTML etc
	###
	### check for reinstall, need for a restart
	###
	@tempdir=nil unless @tempdir
	###
	def self.restart?()
		if @tempdir ### Already loaded once!
			file=File.join(STRINGS, "#{NAME}-#{Sketchup.get_locale.upcase}.strings")
			if File.exist?(file)
				lines=IO.readlines(file)
			else
				file=File.join(STRINGS, "#{NAME}-EN-US.strings")
				if File.exist?(file)
					lines=IO.readlines(file)
				else
					lines=[]
				end
			end
			res=lines.grep(/^RESTARTx=/)
			return unless res[0]
			res.each{|line| eval(line.chomp) }
			UI.messagebox("#{RESTARTx}")
		end
		return
	end
	###
	self.restart?()
	###
	IS_WIN=(RUBY_PLATFORM.downcase =~ /mswin|mingw/) != nil
	IS_MAC=(RUBY_PLATFORM.downcase =~ /darwin/) != nil
	IS_LINUX=(RUBY_PLATFORM.downcase =~ /linux/) != nil
	###
	HOME=File.expand_path( (begin;ENV['HOME'].dup.force_encoding('UTF-8');rescue;ENV['HOME'];end) || (begin;ENV['HOMEPATH'].dup.force_encoding('UTF-8');rescue;ENV['HOMEPATH'];end) || (begin;ENV['HOMEDRIVE'].dup.force_encoding('UTF-8');rescue;ENV['HOMEDRIVE'];end) )
	if IS_MAC
		DESKTOP=File.join(HOME, "Desktop") ### TBC
	else
		DESKTOP=File.join(HOME, "Desktop") ### PC
	end
	###
	[(begin;Sketchup.temp_dir;rescue;'!';end), 
	(begin;ENV['TEMP'].dup.force_encoding('UTF-8');rescue;ENV['TEMP'];end), 
	(begin;ENV['TMP'].dup.force_encoding('UTF-8');rescue;ENV['TMP'];end), 
	(begin;ENV['TMPDIR'].dup.force_encoding('UTF-8');rescue;ENV['TMPDIR'];end), 
	(begin;ENV['USERPROFILE'].dup.force_encoding('UTF-8');rescue;ENV['USERPROFILE'];end),  
	FOLDER, 
	PLUGINS, 
	CONTAINER, 
	HOME, 
	DESKTOP, 
	Dir.pwd, 
	'C:/Temp', 
	'/tmp'
	].each{|d|
		if d && File.directory?(d) && File.writable?(d)
			TEMP = File.expand_path(d)
			break
		end
    }
	###
	TEMPDIR	= File.join(TEMP, NAME)
	@tempdir=TEMPDIR
	begin ### allows for false File.exist? failure with non-ASCII
		Dir.mkdir(TEMPDIR)
	rescue
		###
	end
	### NOUPS scripts never covered by update/installed checks
	NOUPS=[
	"deBabelizer.rb", 
	"ArcCurveTests.rb", 
	"toggleWindows.rb", 
	"delauney3.rb", 
	"inputbox.rb"
	]
	### NONOS == $LOAD_PATH folders BUT NOT custom-plugins - uses // regex
	home = Regexp.new('^'+Regexp.escape(HOME)+'$')
	NONOS=[
	home,
	/\/RubyStdLib/, 
	/\/lib\/ruby\//, 
	/\/[Tt]est[Uu]p\//, 
	/\/[Tt]ools$/, 
	/\/TT_Lib/, 
	/\/SketchyPhysics/, 
	/\/SketchThis/, 
	/\/i[.]materialise/, 
	/\/[Ww]in_[Uu]tils\//, 
	/\/wxSU\//, 
	/\/ASGVIS/, 
	/\/skindigo/
	]
	SUCPLUGINS = HOME+'/sketchUcloud/plugins'
	### 'Helpers' which other scripts might 'require'...
	HELPERS=['progressbar.rb', 
	'offset.rb', 
	'arraysum.rb', 
	'array_to.rb', 
	'getMaterials.rb', 
	'EntsGetAtt.rb', 
	'select.rb', 
	'smustard-app-observer.rb', 
	'deBabelizer.rb', 
	'parametric.rb', 
	'mesh_additions.rb', 
	'su_dynamiccomponents.rb', 
	'add_funcs.rb', 
	'resizing_material.rb', 
	'delauney2.rb', 
	'delauney3.rb', 
	'ftools.rb', 
	'inputbox.rb', 
	'LibFredo6.rb', 
	'LibTraductor.rb', 
	'toggleWindows.rb', 
	'vector.flat_angle.rb', 
	'wxSU.rb', 
	'image_code.rb', 
	'easings.rb', 
	'su2pov34.rbs', 
	'windowizer4stylemanager.rb', 
	'weld.rb', 
	'TIG-weld.rb', 
	'pp.rb'
	].sort
	###
	CREATOR="#{LNAME}"
	COPYRIGHT="#{LNAME} © #{Time.now.year}"
	###
	### set up translated Constants ### File.exists? should always work as all ASCII in path
	file=File.join(STRINGS, "#{NAME}-#{Sketchup.get_locale.upcase}.strings")
	if File.exist?(file)
		lines=IO.readlines(file)
	else
		file=File.join(STRINGS, "#{NAME}-EN-US.strings")
		if File.exist?(file)
			lines=IO.readlines(file)
		else
			lines=[]
		end
	end
	lines.each{|line|
		line.chomp!
		next if line.empty? || line=~/^[#]/
		next unless line=~/[=]/
		eval(line) ### set CONSTANT=value
	}
	###
	EXT=SketchupExtension.new(NAME, File.join(FOLDER, "SCF_loader.rb"))
	EXT.name = LNAME
	EXT.description = "#{LNAME} #{TOOLSS}: #{DESC}, #{MDESC} #{AND} #{XDESC}"
	EXT.version = VERSION
	EXT.creator = CREATOR
	EXT.copyright = COPYRIGHT
	ext=Sketchup.register_extension(EXT, true) # show on 1st install
	###
end#module
