class CreateDrinks < ActiveRecord::Migration
  def up
    change_table :drinks do |t|
      t.rename :drink_id, :id
      t.integer :abv, limit:2 # alcohol by volume
      t.remove :rating
      t.remove :number_of_votes
      t.change :glass_id, :integer, limit:2
      t.text :description
      t.integer :up_vote_ct, default: 0
      t.integer :dn_vote_ct, default: 0
      t.float :score, default:0 # average vote
      t.string :color
      t.integer :revision_id
      t.integer :comment_ct, default: 0
      t.integer :ingredient_ct, default: 0
      t.boolean :profane, default: false
      t.boolean :non_alcoholic, default: false
    end
    add_index :drinks, :name
    execute "UPDATE drinks SET abv = REGEXP_REPLACE(alcohol_contents, '%', '')::integer WHERE LENGTH(alcohol_contents) > 0"
    execute "CREATE SEQUENCE drinks_id_seq"
    execute "ALTER SEQUENCE drinks_id_seq OWNED BY drinks.id"
    execute "ALTER TABLE ONLY drinks ALTER COLUMN id SET DEFAULT nextval('drinks_id_seq'::regclass);"
    remove_column :drinks, :alcohol_contents
  end
end
