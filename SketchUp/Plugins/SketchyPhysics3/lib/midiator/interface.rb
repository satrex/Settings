#!/usr/bin/env ruby
#
# The main entry point into MIDIator.  Create a MIDIator::Interface object and
# off you go.
#
# == Authors
#
# * Ben Bleything <ben@bleything.net>
#
# == Contributors
#
# * Giles Bowkett
# * Jeremy Voorhis
#
# == Copyright
#
# Copyright (c) 2008 Ben Bleything
#
# This code released under the terms of the MIT license.
#

require 'midiator'

class MIDIator::Interface
  attr_reader :driver

  ### Automatically select a driver to use
  def autodetect_driver
    driver = case RUBY_PLATFORM
    when /darwin/
      :dls_synth
    when /cygwin|mingw|mswin/i
      :winmm
    when /linux/
      :alsa
    when /java/
      :mmj if Java::java.lang.System.get_property('os.name') == 'Mac OS X'
    else
      raise "No driver is available."
    end

    self.use(driver)
  end


  ### Attempts to load the MIDI system driver called +driver_name+.
  def use( driver_name )
    path = File.expand_path('../../', __FILE__)
    $LOAD_PATH.insert(0, path)
    driver_path = "midiator/drivers/#{driver_name.to_s}"
    begin
      require driver_path
    rescue LoadError => e
      raise LoadError, "Could not load driver '#{driver_name}'."
    ensure
      $LOAD_PATH.delete_at(0)
    end
    # Fix two side-effects of the camelization process... first, change
    # instances of Midi to MIDI.  This fixes the acronym form but doesn't
    # change, for instance, 'timidity'.
    #
    # Second, the require path is midiator/drivers/foo, but the module
    # name is Driver singular, so fix that.
    driver_class = driver_path.gsub( /\/(.?)/ ) {
      "::" + $1.upcase
    }.gsub( /(^|_)(.)/ ) {
      $2.upcase
    }.gsub( /Midi/, 'MIDI' ).
    sub( /::Drivers::/, '::Driver::')

    # special case for the ALSA driver
    driver_class.sub!( /Alsa/, 'ALSA' )

    # special case for the WinMM driver
    driver_class.sub!( /Winmm/, 'WinMM' )

    # special case for the DLSSynth driver
    driver_class.sub!( /Dls/, 'DLS' )

    # this little trick stolen from ActiveSupport.  It looks for a top-
    # level module with the given name.
    @driver = Object.module_eval( "::#{driver_class}" ).new
  end


  ### A little shortcut method for playing the given +note+ for the
  ### specified +duration+. If +note+ is an array, all notes in it are
  ### played as a chord.
  def play( note, duration = 0.1, channel = 0, velocity = 100 )
    [note].flatten.each do |n|
      @driver.note_on( n, channel, velocity )
    end
    sleep duration
    [note].flatten.each do |n|
      @driver.note_off( n, channel, velocity )
    end
  end


  ### Does nothing for +duration+ seconds.
  def rest( duration = 0.1 )
    sleep duration
  end

  #######
  private
  #######

  ### Checks to see if the currently-loaded driver knows how to do +method+ and
  ### passes the message on if so.  Raises an exception (as normal) if not.
  def method_missing( method, *args )
    raise NoMethodError, "Neither MIDIator::Interface nor #{@driver.class} " +
      "has a '#{method}' method." unless @driver.respond_to? method

    return @driver.send( method, *args )
  end

end
