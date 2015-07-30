class TipsyException::DatabaseException < TipsyException

  # @param result - a PG::Result (return value from PG::Connection.execute)
  # @param expected - number of rows expected to be updated/selected/inserted in UPDATE/SELECT/INSERT command
  def self.assert_row_count(result, expected, query_type)
    unless result.cmd_tuples == expected
      msg = "Incorrect number of rows updated in #{query_type} command."
      msg += " Expected #{expected}."
      msg += " Updated #{result.cmd_tuples}."
      raise self.new(msg)
    end
  end

end
