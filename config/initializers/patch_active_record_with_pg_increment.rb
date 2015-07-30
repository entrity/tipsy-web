class ActiveRecord::Base

  def pg_increment! field, increment=1
    conn = self.class.connection.raw_connection
    table = self.class.table_name
    stmt = "UPDATE #{table} SET #{field} = #{field} + #{increment}"
    stmt += ", updated_at = current_timestamp" if self.class.attribute_method?(:updated_at)
    stmt += " WHERE id = #{id} RETURNING #{field}"
    res = conn.exec(stmt)
    TipsyException::DatabaseException.assert_row_count(res, 1, 'UPDATE')
    self[field] = res.getvalue(0,0).to_i
  end

end
