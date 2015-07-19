require 'db/postgres_functions.rb'

class CreateFnFlagPhotos < ActiveRecord::Migration
  include PostgresFunctions

  def up
    create_flag_fn 'photos'
  end
  def down
    drop_flag_fn 'photos'
  end
end
