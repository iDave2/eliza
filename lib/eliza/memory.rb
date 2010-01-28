class Memory < Array
  
  def initialize
    super
    @max = 20
  end
  
  def get
    shift
  end
  
  def save(s)
    push s
    shift if length > @max
    nil
  end
  
end