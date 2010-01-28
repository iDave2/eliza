class Decomp < Array
  
  attr_accessor :pattern
  attr_reader :mem
  
  def initialize(pattern, mem = false)
    super()
    @pattern = pattern  # a regular expression, see Script#initialize
    @mem     = mem      # save my dialogs in memory?  
    @index   = nil      # locates current reassembly rule 
  end
  
  def nextRule
    raise "error: no reassembly rules for decomp" unless self.size
    @index = rand self.size unless @index
    if (@mem)
      @index = rand self.size
    else
      @index += 1
      @index = 0 unless 0 <= @index and @index < self.size
    end
    String.new self[@index]
  end
  
  def inspect
    "*** Decomp#inspect: @pattern=#@pattern, @mem=#@mem, @index=#@index " + super
  end
  
  def to_s
    "*** Decomp#to_s: @pattern=#@pattern, @mem=#@mem, @index=#@index " + super
  end
  

  
end