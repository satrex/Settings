#!/usr/bin/env ruby
#
# A Ruby library for interacting with system-level MIDI services.
#
# == Authors
#
# * Ben Bleything <ben@bleything.net>
#
# == Copyright
#
# Copyright (c) 2008 Ben Bleything
#
# This code released under the terms of the MIT license.
#

module MIDIator
  VERSION = '0.5.1'
end

dir = File.dirname(__FILE__)
$LOAD_PATH.insert(0, dir)

#####################################################################
###  M I D I A T O R   C O R E
#####################################################################
require 'midiator/driver'
require 'midiator/driver_registry'
require 'midiator/exceptions'
require 'midiator/interface'
require 'midiator/timer'

##########################################################################
### S H O R T C U T   M O D U L E S
##########################################################################
require 'midiator/drums'
require 'midiator/notes'

$LOAD_PATH.delete_at(0)
