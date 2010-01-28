
require 'eliza/key'
require 'eliza/memory'
require 'eliza/script'

class Eliza
  
  def initialize(scriptName, inputStream, outputStream)
    @debug = false
    @delay = 1    # delay in seconds before responding
    @done = false
    @memory = Memory.new
    @memory.save('Oh my gosh, I spilled coffee! Sorry, please continue.')
    @script = Script.new scriptName
    @in, @out = inputStream, outputStream
    srand 1234
  end
  
  def run
    @out.puts ">> Hello."
    @out.puts "Please state your problem."
    @out.print ">> "
    @in.each_line do |input|
      wait_until = Time.now + @delay
      @out.print "#{input}" if @in.kind_of? File
      reply = processInput(input)
      sleep 1 while Time.now < wait_until
      @out.puts reply
      break if @done
      @out.print ">> "
    end
  end
  
  def processInput(input)
    
    # Clean up input string, split into sentences.
    #str = input.tr(',?!', '.').gsub(/[^.'\w]/, ' ').strip.squeeze("\s.")
    str = input.tr(',?!', '.').strip.squeeze("\s.")
    sentences = str.split(/\.\s*/)
    
    # Try each sentence in string.
    sentences.each { |s| (reply = sentence(s)) and return reply }
    
    # No sentence(), pop next FIFO memory, if any.
     (reply = @memory.get) and return reply
    
    # No memory, try processing with xnone key.
    results = {}
    if key = @script.keys['xnone'] then sentences.each { |s|
        decompose(s, key, results) and results['reply'] and return results['reply'] }
    end      
    
    # Oh well, just say anything.
    "I am at a loss for words."
    
  end
  
  def sentence(s)
    
    puts %Q{*** processing sentence "#{s}" ...} if @debug

    results = {} # for results of decomp and assemble
    
    # Pre-replace any matching source terms with their destination.
    s = @script.pre_translate(s)
    
    # Check special case = end of therapy session.
    if @script.quits.include? s
      @done = true
      return @script.final
    end
    
    # Patient isn't done, collect all keywords.
    keys = {} # Start as hash,
    for word in s.split do
      keys[word] = @script.keys[word] if @script.keys[word]
    end
    keys = keys.each_value.sort.reverse # end as array, decreasing precedence
    
    # Try each key for a reply or goto rule. 
    keys.each { |key| 
      next unless decompose(s, key, results)
      return results['reply'] if results['reply']
      # Avoid infinite loops, allow one goto.
      next unless decompose(s, results['goto_key'], results)
      return results['reply'] if results['reply']
    }
    
    # Sorry Charlie, no match found!
    nil
  end
  
  def decompose(input, key, results)
    puts %Q{*** decompose "#{input}" on key "#{key.name}"} if @debug
    key.each { |decomp| 
      if md = decomp.pattern.match(input)
        return true if assemble(md, decomp, results)
      end
    }
    return false
  end
    
    def assemble(md_input, decomp, results)
      if @debug
        captures = %Q["#{md_input.captures.join('", "')}"]
        puts %Q{*** assemble "#{decomp.pattern.inspect}" with (#{captures})} 
      end
      rule = decomp.nextRule
      if rule =~ /^goto\s+(\w+)/
        raise "error: unknown key '#{$1}'" unless @script.keys[$1]
        return (results['goto_key'] = @script.keys[$1])
      end
      while md_rule = /(\((\d)\))/.match(rule) # e.g., (2) => md_input[2]
        i, arg = $2.to_i, "[#{i}]"
        if 0 < i and i < md_input.length
          arg = @script.post_translate(md_input[i]) 
          rule = md_rule.pre_match + arg + md_rule.post_match
        end
      end
      rule.sub!(/\s*(\W)\Z/) { |match| match = $1 }
      @memory.save(rule) if decomp.mem
      results['reply'] = rule
    end
    
  end
