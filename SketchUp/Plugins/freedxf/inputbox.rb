=begin
Inputbox.rb Copyright 2008 jim.foltz@gmail.com

The Inputbox class makes it easy to create user input 
dialogs by providing a consistent interface to UI.inputbox for
text fields and drop-down selection fields.

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=end

require 'sketchup'

# User input box class.
#
class Inputbox

  #
  # Inputbox.new( title )
  # Inputbox.new( title, options )
  #
  #   Creates a new Inputbox using the givien title.
  #   There are no options at this time.
  #
  def initialize(title, opts = {} )
    @title = title
    @prompts = []
    @choices = []
    @values = []
    @defaults = []
  end

  #
  # add( prompt [, choices, default] )
  #
  # Adds the prompt to the inputbox. With no other arguments, defaults to empty text input.
  #
  # Examples: 
  # add "Prompt 1"                            # empty text entry
  # add "Prompt 2", 2.2                       # text entry with default value
  # add "Prompt 3", [10, 12, 14, 16]          # Creates a drop-down selection from the array.
  # add "Prompt 4", %w(One Two Three)         # Defaults to first in list.
  # add "Prompt 5", %w(Four Five Six), "Five" # dropdown, 3 choices, "Five" is default
  # 
  def add(*args)
    case args.length
    when 0
      return UI.messagebox("You need at least one argument.")
    when 1
      add_prompt(args[0])
    when 2
      if args[1].is_a? Array
	add_dropdown(args[0], args[1])
      else
	add_prompt(args[0], args[1])
      end
    when 3
      add_dropdown(args[0], args[1], args[2])
    end
  end

  #
  # show
  #
  #   Displays the inputbox to the user.
  #   Uses the choices and defaults given when the prompt was constructed.
  #   Returns an array of the values entered.
  #
  def show
    ret = inputbox( @prompts, @values, @choices, @title )
    puts "ret:#{ret.inspect}"
    @values = ret unless ret == false # Cancel
    return ret
  end

  #
  # [ Fixnum | String ]
  #
  #   returns the value associated with the given key or index
  #
  def []( key )
    return nil if key.nil?
    if key.is_a? Fixnum
      return @values[key]
    elsif key.is_a? String
      i = @prompts.index(key)
      return @values[i] unless i.nil?
    end
  end

  #
  # reset
  #
  #   Resets the values to the initial defaults
  #
  def reset
    @values = @defaults
  end

  #
  # each { |key, value| block }
  #
  #  Yield each prompt and value to the given block
  #
  def each
    return unless block_given?
    prompts.each_with_index do |pr, i|
      yield pr, @values[i]
    end
  end

  #
  # prompts
  #   
  #   Returns an Array of prompts
  #
  def prompts
    @prompts
  end

  #
  # values
  #
  #  Returns an Array of input values
  #
  def values
    @values
  end

  #
  # save
  #
  #   Save the options to the registry for persistent storage
  #
  def save
    section = "Inputbox_" + @title
    i = "01"
    c = 0
    each do |k, v|
      Sketchup.write_default(section, "Prompt_#{i}", e(k.to_s))
      Sketchup.write_default(section, "Value_#{i}", e(v))
      if v = @choices[c]
	Sketchup.write_default(section, "Choice_#{i}", e(v))
      end
      if  v = @defaults[c]
	Sketchup.write_default(section, "Default_#{i}", e(v))
      end
      i.next!
      c += 1
    end
  end

  #
  # load
  #   
  #   Restores the Iinputbox from the registry.
  #
  def load
    section = "Inputbox_" + @title
    prompts = []
    values = []
    choices  = []
    defaults = []
    c = "01"
    while( prompt =  Sketchup.read_default(section, "Prompt_#{c}") )
      prompts << d(prompt)
      values << d(Sketchup.read_default(section, "Value_#{c}"))
      choices << d(Sketchup.read_default(section, "Choice_#{c}"))
      defaults << d(Sketchup.read_default(section, "Default_#{c}"))
      c.next!
    end
    @prompts = prompts
    @values = values
    @choices = choices
    @defaults = defaults
  end

  def to_hash
    h = {}
    each { |k, v|
      h[k] = v
    }
    return h
  end


  private
  #
  # These are helper methods for the add method and are
  # not available to the Inputbox user.
  #
  def add_prompt(prompt, default = nil)
    @prompts << prompt
    @values << default
    @defaults << default
    @choices << nil
  end

  def add_dropdown(prompt, choices, default = nil)
    @prompts << prompt
    @choices << choices.join("|")
    if default.nil?
      @values << choices[0]
      @defaults << choices[0]
    else
      @values << default
      @defaults <<  default
    end
  end

  #
  # e
  #
  #   Encode (escape) strings for writing to registry
  #
  def e(str)
    if str.is_a? String
      #str.gsub!(/%/, '\%')
      #str.gsub!(/"/, '\"')
      str.gsub!(/"/, '\"')
      #str.gsub!(/#/, '\#')
      str.gsub!(/\\/, '/')
      return str
      #s = [str].pack("a")
    end
  end

  #
  # d( string )
  #
  #   Decodes values read from Registry.
  #
  def d(s)
    s
  end

end # class Inputbox

