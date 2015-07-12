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

  def self.autocomplete(search_term, opts={})
    pattern = FuzzyFindable.fuzzify(search_term)
    selects = []
    selects.push(fuzzy_sql(DRINK, Drink.table_name, opts[:profane])) unless opts[:drinks] == false
    selects.push(fuzzy_sql(INGREDIENT, Ingredient.table_name, opts[:profane])) unless opts[:ingredients] == false
    query = selects.join(' UNION ') + " LIMIT #{MAX_RESULTS}"
    res = ActiveRecord::Base.connection.raw_connection.exec_params(query, [pattern])
    res.to_a
  end

  def self.fuzzify(search_term)
    "%#{search_term.chars.join('%')}%"
  end

  private

    def self.fuzzy_sql type_id, table_name, profane
      %Q(SELECT id, name, #{type_id} AS type
      #{', profane' if profane == false}
      FROM #{table_name} WHERE name ILIKE $1
      #{' AND profane = '+profane.to_s if profane == false})
    end

end