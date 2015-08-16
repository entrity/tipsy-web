class CreateFavouritesAndFavouritesCollections < ActiveRecord::Migration
  def change
    create_table :favourites do |t|
      t.integer :user_id
      t.integer :drink_id
      t.integer :collection_id
    end
    add_index :favourites, [:user_id, :drink_id]
    add_index :favourites, [:collection_id, :drink_id, :user_id]
    create_table :favourites_collections do |t|
      t.integer :user_id
      t.string  :name
      t.string  :preview_urls, array: true
      t.integer :favourite_ct, default: 0
    end
    add_index :favourites_collections, [:user_id, :name]
  end
end
