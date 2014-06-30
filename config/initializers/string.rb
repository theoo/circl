class String
  def is_i?
     /^[-+]?\d+$/ === self
  end

  def exerpt(number_of_chars = 250)
    if self.size > number_of_chars
      self[0..number_of_chars] + " (...)"
    else
      self
    end
  end
end