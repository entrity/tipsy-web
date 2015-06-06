class AddCountsToDrinks < ActiveRecord::Migration
  def change
    add_column :drinks, :comment_ct, :integer, default: 0
    add_column :drinks, :ingredient_ct, :integer, default: 0
    add_column :drinks, :profane, :boolean, default: false
    add_column :drinks, :non_alcoholic, :boolean, default: false
  end
end
