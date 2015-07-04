class MakeRevisionsCreatable < ActiveRecord::Migration
  def up
    execute 'CREATE EXTENSION hstore'
    change_table :revisions do |t|
      t.text    :name
      t.text    :description
      t.text    :prep_time
      t.integer :calories
      t.integer :parent_id
      t.boolean :non_alcoholic, default: false
      t.boolean :profane, default: false
      t.hstore  :ingredients, array: true, default: '{}'
      t.rename  :revisable_id, :drink_id
      t.rename  :text, :instructions
      t.remove :revisable_type
      t.remove :updated_at
    end
  end

  def down
    change_table :revisions do |t|
      t.remove :name
      t.remove :description
      t.remove :prep_time
      t.remove :calories
      t.remove :parent_id
      t.remove :ingredients
      t.remove :non_alcoholic
      t.remove :profane
      t.rename    :drink_id, :revisable_id
      t.rename    :instructions, :text
      t.text      :revisable_type
      t.timestamp :updated_at
    end
    execute 'DROP EXTENSION hstore'
  end
end
