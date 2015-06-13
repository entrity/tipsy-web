module FuzzyFindable
  DRINK = 0
  INGREDIENT = 1
  MAX_RESULTS = 100

  def self.included(base)
    base.class_eval do
      scope :fuzzy_find, -> term {
        pattern = FuzzyFindable.fuzzify(term)
        where("#{base.table_name}.name LIKE ?", pattern)
      }
    end
  end

  def self.autocomplete(search_term, profane=nil)
    pattern = FuzzyFindable.fuzzify(search_term)
    profane = nil unless profane.to_s =~ /1|0|true|false/i
    query = %Q(SELECT id, name, #{DRINK} AS type
      #{', profane' unless profane.nil?}
      FROM drinks WHERE name ILIKE '#{pattern}'
      #{' AND profane = '+profane.to_s unless profane.nil?}
      UNION
      SELECT id, name, #{INGREDIENT} AS type
      #{', false as profane' unless profane.nil?}
      FROM ingredients WHERE name ILIKE '#{pattern}'
      LIMIT #{MAX_RESULTS})
    cursor = ActiveRecord::Base.connection.execute(query)
    cursor.to_a
  end

  def self.fuzzify(search_term)
    "%#{search_term.chars.join('%')}%"
  end

end