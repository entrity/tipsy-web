PointDistributionCategory = Struct.new(:id, :points, :message)

begin
  categories = YAML::load_file(File.join Rails.root, 'config/point_distribution_categories.yml')
  categories.each_with_index do |hash, index|
    category = PointDistributionCategory.new index+1, hash['points'], hash['message']
    category.freeze
    PointDistributionCategory.const_set hash['name'], category
  end
end
