require 'sketchup.rb'

dir = File.dirname(__FILE__)
if RUBY_VERSION =~ /1.8/
  require File.join(dir, 'lib/dl/import.rb')
  require File.join(dir, 'lib/dl/struct.rb')
  if RUBY_PLATFORM =~ /mswin|mingw/i
    require File.join(dir, 'lib/Win32API')
  end
else
  # Use fiddle from the tools folder.
  require 'fiddle/import.rb'
  if RUBY_PLATFORM =~ /mswin|mingw/i
    require 'Win32API' # Use one from the tools folder.
  end
end

# Make this version global for now. Needed to allow legacy scripted joints to work.
def getKeyState(key)
    MSketchyPhysics3.getKeyState(key)
end

#GetKeys.getKeyState(VK_LCONTROL) whenever you want to check for control key and
#GetKeys.getKeyState(VK_LSHIFT) whenever you want to check for shift

module MSketchyPhysics3

if RUBY_PLATFORM =~ /mswin|mingw/i
    extend RUBY_VERSION =~ /1.8/ ? DL::Importable : Fiddle::Importer
    dlload 'user32.dll'
    extern "int SetCursorPos(int, int)"
    extern "int GetCursorPos(void*)"
    extern "int ShowCursor(int)"

    GetKeyState = Win32API.new('User32.dll', 'GetKeyState', ['N'], 'N')

    # In Ruby 2.x.x all capitalized functions remain capitalized.
    if RUBY_VERSION.to_f > 1.8
      def self.setCursorPos(*args); SetCursorPos(*args) end
      def self.getCursorPos(*args); GetCursorPos(*args) end
      def self.showCursor(*args); ShowCursor(*args) end
    end

    class << self

        def getCursor
            if RUBY_VERSION =~ /1.8/
                buf = (0.chr*8).to_ptr
                getCursorPos(buf)
                buf.to_a('L2')
            else
                buf = Fiddle::Pointer.malloc(8)
                getCursorPos(buf)
                buf.to_str.unpack('LL')
            end
        end

        def setCursor(x,y)
            setCursorPos(x,y)
        end

        def hideCursor(bool)
            if bool
                while(showCursor(0) > -1); end
            else
                while(showCursor(1) <= 0); end
            end
        end

        def getKeyState(vk)
            (GetKeyState.call(vk)%256 >> 7) != 0
        end

    end # proxy class

else # Must be using Mac OS X.

    dir = File.dirname(__FILE__)

    extend RUBY_VERSION =~ /1.8/ ? DL::Importable : Fiddle::Importer
    dlload File.join(dir, 'lib/GetKeys.dylib')
    extern "int TestForKeyDown(short)"

    # In Ruby 2.x.x all capitalized functions remain capitalized.
    if RUBY_VERSION.to_f > 1.8
      def self.testForKeyDown(*args); TestForKeyDown(*args) end
    end

    class << self

        def getCursor
            # not working yet
            [0,0]
        end

        def setCursor(x,y)
            # not working yet
        end

        def hideCursor(bool)
            # not working yet
        end

        def getKeyState(vk)
            testForKeyDown(vk) != 0
        end

    end # proxy class
end

end # module MSketchyPhysics3


module MSketchyPhysics3::JoyInput

    dir = File.dirname(__FILE__)
    extend RUBY_VERSION =~ /1.8/ ? DL::Importable : Fiddle::Importer
    if RUBY_PLATFORM =~ /mswin|mingw/i
        dlload File.join(dir, 'lib/WinInput.dll')
    else
        dlload File.join(dir, 'lib/MacInput.dylib')
    end
    extern "int initInput()"
    extern "int readJoystick(void*)"
    extern "void freeInput()"
    JOY_STATE = struct([
        'int lX',
        'int lY',
        'int lZ',
        'int lRx',
        'int lRy',
        'int lRz',
        'int rglSlider[2]',
        'int rgdwPOV[4]',
        'char rgbButtons[128]',
        'int lVX',
        'int lVY',
        'int lVZ',
        'int lVRx',
        'int lVRy',
        'int lVRz',
        'int rglVSlider[2]',
        'int lAX',
        'int lAY',
        'int lAZ',
        'int lARx',
        'int lARy',
        'int lARz',
        'int rglASlider[2]',
        'int lFX',
        'int lFY',
        'int lFZ',
        'int lFRx',
        'int lFRy',
        'int lFRz',
        'int rglFSlider[2]'
    ])
    @cur_joy_state = JOY_STATE.malloc

    class << self

        def state
            @cur_joy_state
        end

        def updateInput
            # Fix for SU2014 which leaves the first value dirty when the controller is not connected.
            @cur_joy_state.lX = 0
            @cur_joy_state.lY = 0
            @cur_joy_state.lRx = 0
            @cur_joy_state.lRy = 0
            readJoystick(@cur_joy_state.to_ptr)
            @cur_joy_state
        end

    end # proxy class

end # module MSketchyPhysics3::JoyInput
