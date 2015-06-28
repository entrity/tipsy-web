module ApplicationHelper

  def glass_image_tag glass_id, background_color
    image_tag "/images/glass-#{glass_id}.png", style:"background-color:#{background_color}"
  end

  def drink_ingredient_json drink_ingredient
    drink_ingredient.ingredient.as_json(only:[:name, :id]).to_json
  end

end
