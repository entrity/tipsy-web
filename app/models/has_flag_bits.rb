module HasFlagBits
  SPAM       = (1<<0)
  INDECENT   = (1<<1)
  COPYRIGHT  = (1<<2)

  def self.included(base)
    unless base.attribute_method?(:flag_bits)
      raise "No flag_bits column on class #{base.name}"
    end
  end
  
  def copyright_flag?
    (flag_bits & COPYRIGHT) != 0
  end

  def indecent_flag?
    (flag_bits & INDECENT) != 0
  end

  def spam_flag?
    (flag_bits & SPAM) != 0
  end

end
