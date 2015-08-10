class DrinkSuggestion < Drink
  attr_reader :distance
  attr_accessor :diff

  def distance= val
    @distance = val.nil? ? nil : val.to_i
  end

end
