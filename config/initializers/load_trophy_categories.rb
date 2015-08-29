TrophyCategory = Struct.new(:id, :colour, :name, :description)
TrophyCategory::BRONZE = 1
TrophyCategory::SILVER = 2
TrophyCategory::GOLD   = 3

begin
  categories = YAML::load_file(File.join Rails.root, 'config/trophy_categories.yml')
  TrophyCategory::ALL = Array.new(categories.length)
  categories.each_with_index do |hash, index|
    colour   = TrophyCategory.const_get hash['colour']
    category = TrophyCategory.new index, colour, hash['name'], hash['description']
    category.freeze
    TrophyCategory::ALL[index] = category
    TrophyCategory.const_set hash['const'], category
  end
end
