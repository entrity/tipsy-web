module FuzzyFindable
  DRINK = 0
  INGREDIENT = 1
  MAX_RESULTS = 30

  def self.included(base)
    base.class_eval do
      scope :fuzzy_find, -> term {
        pattern = FuzzyFindable.fuzzify(term)
        where("#{base.table_name}.name LIKE ?", pattern)
      }
    end
  end

  def self.autocomplete(search_term, opts={})
    selects = []
    selects.push(fuzzy_sql(DRINK, Drink.table_name, opts[:profane])) unless opts[:drinks] == false
    selects.push(fuzzy_sql(INGREDIENT, Ingredient.table_name, opts[:profane], opts[:exclude_ingredient_ids])) unless opts[:ingredients] == false
    query = selects.join(' UNION ') + " ORDER BY distance LIMIT #{MAX_RESULTS}"
    res = ActiveRecord::Base.connection.raw_connection.exec_params(query, [fuzzify(search_term, true), fuzzify(search_term)])
    res.to_a
  end

  def self.fuzzify(search_term, no_external_wildcards=false)
    pattern = search_term.chars.join('%')
    return no_external_wildcards ? pattern : "%#{pattern}%"
  end

  private

    def self.fuzzy_sql type_id, table_name, profane, exclude_ids=nil
      query = "SELECT id, name, #{type_id} AS type, LEVENSHTEIN_LESS_EQUAL($1, name, 10) AS distance"
      query += ", profane" if profane == false
      query += " FROM #{table_name} WHERE name ILIKE $2"
      query += " AND id NOT IN (%s)" % exclude_ids.join(',') if exclude_ids.present?
      query += " AND profane = "+profane.to_s if profane == false
      query
    end

end