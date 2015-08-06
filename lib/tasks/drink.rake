namespace :drink do
  task :set_related => :environment do
    Drink.all.each do |drink|
      ingredient_ids = drink.ingredients.pluck(:ingredient_id)
      candidates = Drink
        .joins(:ingredients)
        .where('drinks_ingredients.ingredient_id' => ingredient_ids)
        .includes(:ingredients)
        .distinct
      candidates.to_a.sort! do |a, b|
        cda = common_ingredients(drink, a)
        cdb = common_ingredients(drink, b)
        if common_ingredients(drink, a) == common_ingredients(drink, b)
          ingredient_ct_diff(drink, a) <=> ingredient_ct_diff(drink, b)
        else
          common_ingredients(drink, a) <=> common_ingredients(drink, b)
        end
      end
      related_drinks = candidates[0...5]
      drink.update_attributes! related_drink_ids:related_drinks.map(&:id)
    end
  end

  def common_ingredients drink, other
    attr_name = "@drink_#{drink.id}_common_ingredients"
    other.instance_variable_get(attr_name) || begin
      count = (drink.ingredients.map(&:ingredient_id) & other.ingredients.map(&:ingredient_id)).length
      other.instance_variable_set attr_name, count
    end
  end

  def ingredient_ct_diff drink, other
    attr_name = "@drink_#{drink.id}_distinct_ingredients"
    other.instance_variable_get(attr_name) || begin
      count = (drink.ingredients.length - other.ingredients.length).abs
      other.instance_variable_set attr_name, count
    end
  end
end
