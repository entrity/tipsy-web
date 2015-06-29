class CreateIngredients < ActiveRecord::Migration
  def change
    change_table :ingredients do |t|
      t.rename :ingredient_id, :id
      t.text :description
      t.integer :revision_id
    end
    execute "CREATE SEQUENCE ingredients_id_seq"
    execute "ALTER SEQUENCE ingredients_id_seq OWNED BY ingredients.id"
    execute "ALTER TABLE ONLY ingredients ALTER COLUMN id SET DEFAULT nextval('ingredients_id_seq'::regclass);"
    add_index :ingredients, :name
  end
end
