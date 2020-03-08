require 'sketchup.rb'

dir = File.dirname(__FILE__)
require File.join(dir, 'lib/midiator.rb')

module MSketchyPhysics3
  class << self

    def testDrums
        dir = File.dirname(__FILE__)
        path = File.join(dir, 'sounds/edge1.xml')
        return false unless File.exists?(path)
        lines = File.readlines(path)
        score = parseScore(lines)
        playScore(score)
    end

    def playScore(events)
        mi = MIDIator::Interface.midiInterface
        0.upto(1000) { |tick|
            next unless events[tick]
            events[tick].each { |event|
                mi.startNote(event[2], event[3], event[1]-1)
            }
            sleep(0.030)
        }
    end

    def testEncode(name)
        path = File.join(dir, "sounds/#{name}")
        return unless File.exists?(path)
        lines = File.readlines(path)
        encodeScore(lines)
    end

    def encodeScore(lines)
        note_events = {}
        lines.each_with_index { |l,i|
            if l.include?("<Absolute>")
                tick=l.split(/[><]/)[2].to_i
                # tick /= 10
                event = lines[i+1]
                # event = '<NoteOn Channel="10" Note="46" Velocity="0"/>'
                # Clear out the cruft.
                event.gsub!(/[><\/\"]/, '')
                parts = event.split(' ')
                # puts parts
                if parts[0] == 'NoteOn' || parts[0] == 'NoteOff'
                    channel = parts[1].split('=')[1].to_i
                    note = parts[2].split('=')[1].to_i
                    velocity = parts[3].split('=')[1].to_i
                    amount = 1.0
                    amount = 0.0 if parts[0] == 'NoteOff'
                    amount = 0.0 if velocity.zero?
                    #note_desc = (channel<<8) + note
                    #note_events[note_desc] = {} unless note_events[note_desc]
                    #note_events[note_desc][tick] = [amount, velocity]
                    note_desc = "#{channel.to_s}:#{note.to_s}"
                    note_events[note_desc] ||= []
                    note_events[note_desc] << [tick, amount, velocity]
                    #puts [tick, parts[0], channel, note, velocity].join(":")
                end
            end
        }
        sorted_events = {}
        note_events.each { |k,v|
            s = v.sort { |x,y| x[0]<=>y[0] }
            sorted_events[k] = s
        }
        sorted_events
    end

    def parseScore(lines)
        midi_events = {}
        lines.each_with_index { |l,i|
            if l.include?("<Absolute>")
                tick = l.split(/[><]/)[2].to_i
                tick /= 10
                event = lines[i+1]
                #event = '<NoteOn Channel="10" Note="46" Velocity="0"/>'
                # Clear out the cruft.
                event.gsub!(/[><\/\"]/, '')
                parts = event.split(' ')
                #puts parts
                if parts[0] == 'NoteOn'
                    channel=parts[1].split('=')[1].to_i
                    note=parts[2].split('=')[1].to_i
                    velocity=parts[3].split('=')[1].to_i
                    midi_events[tick] ||= []
                    midi_events[tick] << [parts[0], channel, note, velocity]
                    #puts [tick, parts[0], channel, note, velocity].join(":")
                end
            end
        }
        midi_events
    end

  end # class << self
end # module MSketchyPhysics3


class MIDIator::Interface

    @@instance = nil

    def self.midiInterface
        unless @@instance
            @@instance = MIDIator::Interface.new
            @@instance.autodetect_driver
        end
        @@instance
    end

    def setInstrument(channel, instrument)
        #SPMIDI.midiOutShortMsg(@hMidi, (256*instrument)+192+channel)
        @driver.program_change(channel, instrument)
    end

    def startNote(note, velocity = 99, channel = 0)
        #SPMIDI.midiOutShortMsg(@hMidi, (velocity*256+note)*256+144+channel)
        @driver.note_on(note, channel, velocity)
    end

    def stopNote(note, velocity = 99, channel = 0)
        #SPMIDI.midiOutShortMsg(@hMidi, (velocity*256+note)*256+128+channel)
        @driver.note_off(note, channel, velocity)
    end

    def stopAll
        0.upto(16) { |c|
            control_change(0x7f, c, 0)
        }
    end

end # class MIDIator::Interface
