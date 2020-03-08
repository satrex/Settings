#!/usr/bin/env ruby
#
# The MIDIator driver to interact with OSX's CoreMIDI.  Taken more or less
# directly from Practical Ruby Projects.
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

class MIDIator::Driver::CoreMIDI < MIDIator::Driver # :nodoc:
  ##########################################################################
  ### S Y S T E M   I N T E R F A C E
  ##########################################################################
  module C # :nodoc:
    extend RUBY_VERSION =~ /1.8/ ? DL::Importable : Fiddle::Importer
    dlload '/System/Library/Frameworks/CoreMIDI.framework/Versions/Current/CoreMIDI'

    extern "int MIDIClientCreate( void*, void*, void*, void* )"
    extern "int MIDIClientDispose( void* )"
    extern "int MIDIGetNumberOfDestinations()"
    extern "void* MIDIGetDestination( int )"
    extern "int MIDIOutputPortCreate( void*, void*, void* )"
    extern "void* MIDIPacketListInit( void* )"
    extern "void* MIDIPacketListAdd( void*, int, void*, int, int, int, void* )"
    extern "int MIDISend( void*, void*, void* )"

    # In Ruby 2.x.x all capitalized functions remain capitalized.
    if RUBY_VERSION.to_f > 1.8
      def self.mIDIClientCreate(*args); MIDIClientCreate(*args) end
      def self.mIDIClientDispose(*args); MIDIClientDispose(*args) end
      def self.mIDIGetNumberOfDestinations(*args); MIDIGetNumberOfDestinations(*args) end
      def self.mIDIGetDestination(*args); MIDIGetDestination(*args) end
      def self.mIDIOutputPortCreate(*args); MIDIOutputPortCreate(*args) end
      def self.mIDIPacketListInit(*args); MIDIPacketListInit(*args) end
      def self.mIDIPacketListAdd(*args); MIDIPacketListAdd(*args) end
      def self.mIDISend(*args); MIDISend(*args) end
    end
  end

  module CF # :nodoc:
    extend RUBY_VERSION =~ /1.8/ ? DL::Importable : Fiddle::Importer
    dlload '/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation'

    extern "void* CFStringCreateWithCString( void*, char*, int )"

    # In Ruby 2.x.x all capitalized functions remain capitalized.
    if RUBY_VERSION.to_f > 1.8
      def self.cFStringCreateWithCString(*args); CFStringCreateWithCString(*args) end
    end
  end

  ##########################################################################
  ### D R I V E R   A P I
  ##########################################################################

  def open
    client_name = CF.cFStringCreateWithCString( nil, "MIDIator", 0 )
    if RUBY_VERSION =~ /1.8/
      @client = DL::PtrData.new( nil )
    else
      @client = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    end
    C.mIDIClientCreate( client_name, nil, nil, @client.ref )

    port_name = CF.cFStringCreateWithCString( nil, "Output", 0 )
    if RUBY_VERSION =~ /1.8/
      @outport = DL::PtrData.new( nil )
    else
      @outport = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    end
    C.mIDIOutputPortCreate( @client, port_name, @outport.ref )

    number_of_destinations = C.mIDIGetNumberOfDestinations
    raise MIDIator::NoMIDIDestinations if number_of_destinations < 1
    @destination = C.mIDIGetDestination( 0 )
  end

  def close
    C.mIDIClientDispose( @client )
  end

  def message( *args )
    if RUBY_VERSION =~ /1.8/
      format = "C" * args.size
      bytes = args.pack( format ).to_ptr
      packet_list = DL.malloc( 256 )
    else
      bytes = args.pack('C*')
      packet_list = 0.chr*256
    end
    packet_ptr = C.mIDIPacketListInit( packet_list )

    # Pass in two 32-bit 0s for the 64 bit time
    packet_ptr = C.mIDIPacketListAdd( packet_list, 256, packet_ptr, 0, 0, args.size, bytes )

    C.mIDISend( @outport, @destination, packet_list )
  end
end
