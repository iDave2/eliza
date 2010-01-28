
require 'eliza/decomp'
require 'eliza/key'
require 'eliza/pre_post'
require 'pp'

class Script
  
  attr_reader :final, :keys, :quits
  
  def initialize(inputScript = 'script')
    @final      = ''
    @initial    = ''
    @keys       = {}
    @post       = {}
    @pre        = {}
    @quits      = []
    @syns       = {}
    
    parse inputScript

    # Regular expressions are harder to setup but later results look prettier
    # than stepping thru and comparing multiple arrays of words and '*'s.

    synpat = /@(\w+)/ # synonym notation used in eliza scripts
    @keys.each_value { |key|
      key.each { |decomp| # Key is (also) array of Decomp's, maybe too sneaky...
        while synpat.match(decomp.pattern)
          expr = @syns[$1] or raise "error: unknown synonym: '#{$1}'."
          decomp.pattern = $` + "(#{expr})" + $'
        end
        #puts "final pattern(#{decomp.pattern})"
        decomp.pattern = /#{decomp.pattern}/i
      }
    }
  end
  
  def pre_translate(str)
    translate(@pre, str)
  end
  
  def post_translate(str)
    translate(@post, str)
  end
  
  private
  
  def parse(inputScript)
    
    key, decomp = nil
    
    File.new(inputScript).each { |line|
      
      case line
        
      when /^\s*#/                 then # comment line
      when /^\s*final:(.*)/        then @final = $1.strip
      when /^\s*initial:(.*)/      then @initial = $1.strip
      when /^\s*quit:(.*)/         then @quits.push $1.strip
        
      when /^\s*pre:\s*(\S+)(.*)/
        src, dst = $1.downcase, $2.strip
        @pre[src] = PrePost.new(src, dst)
        
      when /^\s*post:\s*(\S+)(.*)/
        src, dst = $1.downcase, $2.strip
        @post[src] = PrePost.new(src, dst)
        
      when /^\s*synon:(.*)/
        names = $1.downcase.split.sort
        pattern = names.join('|')
        names.each { |name| @syns[name] = pattern }
        
      when /^\s*key:(.*)/
        name, rank = $1.downcase.split
        key = @keys[name] = Key.new(name, rank, @keys.size - 1)
        decomp = nil
        
      when /^\s*decomp:\s*(.*)/
        key or raise "#@scriptName(#$.): Error: no key for decomp."
        pattern = $1.downcase.gsub('**', '*').gsub('*', ' * ').strip.squeeze(' ')
        #puts "=== before: #{pattern} ==="
        words = pattern.split
        if words[0] == "$" then mem = true; words.shift
        else mem = false end
        raise "#{@scriptName}($.): error: empty decomp!" if words.size == 0
        pattern = ''
        words.each_index { |i|
          if words[i] == '*'
            if i == words.size - 1  # '*' at end of sentence (greedy)
              pattern += '(.*)' 
            elsif i > 0             # '*' between words
              pattern += '((?:\s(?:\S+\s)*?)+?)'
            else                    # '*' at beginning
              pattern += '(\S+ )*?'
            end
          else # words[i] != '*'
            pattern += words[i]
            pattern += ' ' if i < words.size - 1 and words[i+1] != '*'
          end
        }
        #puts "=== after: #{pattern} ==="
        key.push( decomp = Decomp.new( pattern, mem ))
        
      when /^\s*reasmb:(.*)/
        decomp or raise "#@scriptName($.): Error: no decomp for reasmb!"
        decomp.push $1.strip
        
      else
        $stderr << "Unrecognized script input, line #$.: #{line}\n"
      end
    }
  end
  
  def translate(map, str)
   (words = str.split).each_index { |i|
      pre_post = map[words[i].downcase]
      words[i] = pre_post.dst if pre_post
    }
    words.join ' '
  end
  
end