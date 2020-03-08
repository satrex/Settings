#!/usr/bin/env ruby
#
# The MIDIator driver to interact with Windows Multimedia.  Taken more or less
# directly from Practical Ruby Projects.
#
# NOTE: as yet completely untested.
#
# == Authors
#
# * Topher Cyll
# * Ben Bleything <ben@bleything.net>
#
# == Copyright
#
# Copyright (c) 2008 Topher Cyll
#
# This code released under the terms of the MIT license.
#

if RUBY_VERSION =~ /1.8/
  require File.expand_path('../../../dl/import', __FILE__)
else
  require 'fiddle/import.rb'
end

require 'midiator'
require 'midiator/driver'
require 'midiator/driver_registry'

class MIDIator::Driver::WinMM < MIDIator::Driver # :nodoc:
  module C # :nodoc:
    extend RUBY_VERSION =~ /1.8/ ? DL::Importable : Fiddle::Importer

    dlload 'winmm'
    extern "int midiOutOpen(HMIDIOUT*, int, int, int, int)"
    extern "int midiOutClose(int)"
    extern "int midiOutShortMsg(int, int)"
  end

  def open
    if RUBY_VERSION =~ /1.8/
      @device = DL.malloc(DL.sizeof('I'))
    else
      @device = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
    end
    C.midiOutOpen(@device, -1, 0, 0, 0)
  end

  def close
    C.midiOutClose(@device.ptr.to_i)
  end

  def message(one, two = 0, three = 0)
    message = one + (two << 8) + (three << 16)
    C.midiOutShortMsg(@device.ptr.to_i, message)
  end
end
