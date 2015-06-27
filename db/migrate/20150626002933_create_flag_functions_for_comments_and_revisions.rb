require 'db/postgres_functions.rb'

class CreateFlagFunctionsForCommentsAndRevisions < ActiveRecord::Migration
  include PostgresFunctions
  def up
    create_flag_fn 'comments'
    create_flag_fn 'revisions'
  end
  def down
    drop_flag_fn 'comments'
    drop_flag_fn 'revisions'
  end
end
