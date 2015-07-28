module ApplicationHelper

  def glass_image_tag glass_id, background_color
    image_tag "/images/glass-#{glass_id}.png", style:"background-color:#{background_color}"
  end

  def drink_ingredient_json drink_ingredient
    drink_ingredient.ingredient.as_json(only:[:name, :id]).to_json
  end

  def trophy_icon trophy
    colour_text = case trophy.category.colour
    when TrophyCategory::GOLD;   'gold'
    when TrophyCategory::SILVER; 'silver'
    when TrophyCategory::BRONZE; 'bronze'
    end
    content_tag :i, nil, class: "fa fa-trophy #{colour_text}"
  end

end
