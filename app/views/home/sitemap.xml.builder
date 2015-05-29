base_url = "http://#{request.host_with_port}"
xml.instruct! :xml, :version=>'1.0'
xml.tag! 'urlset', 'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9' do
  xml.url{
      xml.loc(base_url)
      xml.changefreq("yearly")
      xml.priority(0.5)
  }
  @drinks.each do |drink|
    xml.url {
      xml.loc drink_url(drink)
      xml.changefreq("yearly")
      xml.priority(0.6)
    }
  end
  @ingredients.each do |ingredient|
    xml.url {
      xml.loc ingredient_url(ingredient)
      xml.changefreq("yearly")
      xml.priority(0.4)
    }
  end
end