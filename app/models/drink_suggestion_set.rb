class DrinkSuggestionSet < Array

  def initialize canonical_ingredient_ids
    @diffs = {} # Hash of (Array of differing ingredient ids) > (DrinkSuggestionSet::Collection)
    Drink.suggestions(canonical_ingredient_ids).each do |hash|
      self << DrinkSuggestionSet::Suggestion.new(hash, canonical_ingredient_ids)
    end
  end

  def << suggestion
    # Add suggestion to array of suggestions whose diff is the same
    collection = @diffs[suggestion.diff] ||= Collection.new
    collection << suggestion
    # Update @longest_collection if necessary
    if @longest_collection.nil? || collection > @longest_collection
      @longest_collection = collection
    end
  end

  def output
    if @longest_collection
      needed_ingredients = Ingredient.where(id:@longest_collection.diff)
      {drinks:@longest_collection, ingredients:needed_ingredients} # return value
    end
  end

  class Suggestion < Drink
    attr_reader :distance
    attr_accessor :diff

    def initialize attrs, parameter_ingredient_ids
      super(attrs)
      @diff = required_canonical_ingredient_ids - parameter_ingredient_ids
    end

    def distance= val
      @distance = val.nil? ? nil : val.to_i
    end

    def save
      raise "Never to be called"
    end

  end

  class Collection < Array
    attr_reader :distance, :diff

    def << suggestion
      super
      @distance ||= suggestion.distance
      @diff ||= suggestion.diff
    end

    def > other_collection
      return true if length > other_collection.length
      return false if length < other_collection.length
      return @distance < other_collection.distance
    end

  end

end