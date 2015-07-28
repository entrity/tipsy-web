PointDistributionCategory = Struct.new(:id, :points, :message)

begin
  categories = YAML::load_file(File.join Rails.root, 'config/point_distribution_categories.yml')
  PointDistributionCategory::ALL = Array.new(categories.length)
  categories.each_with_index do |hash, index|
    category = PointDistributionCategory.new index, hash['points'], hash['message']
    category.freeze
    PointDistributionCategory::ALL[index] = category
    PointDistributionCategory.const_set hash['name'], category
  end
end
