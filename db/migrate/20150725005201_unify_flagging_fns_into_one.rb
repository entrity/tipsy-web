require 'db/postgres_functions.rb'

class UnifyFlaggingFnsIntoOne < ActiveRecord::Migration
  include PostgresFunctions
  def up
    drop_flag_fn 'comments'
    drop_flag_fn 'photos'
    drop_flag_fn 'revisions'
    ActiveRecord::Base.connection.raw_connection.exec "CREATE TYPE flag_fn_return_type AS (flag_created BOOLEAN, review_created BOOLEAN, flag_id INT)"
    ActiveRecord::Base.connection.raw_connection.exec File.read('lib/db/create_flag_record_fn.sql')
  end

  def down
    ActiveRecord::Base.connection.raw_connection.exec "DROP FUNCTION flag_record (s_table_name TEXT, i_user_id INT, i_flaggable_id INT, s_flaggable_type TEXT, i_flag_limit INT, i_flag_bits INT, i_flag_pts INT, s_description TEXT, dt_timestamp TIMESTAMP)"
    ActiveRecord::Base.connection.raw_connection.exec "DROP TYPE flag_fn_return_type"
    create_flag_fn 'comments'
    create_flag_fn 'photos'
    create_flag_fn 'revisions'
  end
end
