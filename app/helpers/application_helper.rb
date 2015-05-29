module ApplicationHelper

  def glass_image_tag glass_id, background_color
    image_tag "/images/glass-#{glass_id}.png", style:"background-color:#{background_color}"
  end

end
