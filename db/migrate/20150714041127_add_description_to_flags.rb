require 'db/postgres_functions.rb'

class AddDescriptionToFlags < ActiveRecord::Migration
  include PostgresFunctions
  def change
    add_column :flags, :description, :text
    drop_flag_fn('revisions')
    create_flag_fn('revisions')
    drop_flag_fn('comments')
    create_flag_fn('comments')
  end
end
