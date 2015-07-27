class AddTitleAndDescriptionToPointDistributions < ActiveRecord::Migration
  def change
    change_table :point_distributions do |t|
      t.string :title
      t.string :description
      t.string :url
    end
  end
end
