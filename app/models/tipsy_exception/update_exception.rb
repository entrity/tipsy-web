class TipsyException::UpdateException < TipsyException::Exception

  # @param result - a PG::Result (return value from PG::Connection.execute)
  # @param expected - number of rows expected to be updated in UPDATE command
  def self.assert_update_count(result, expected)
    unless result.cmd_tuples == expected
      msg = "Incorrect number of rows updated in UPDATE command."
      msg += " Expected #{expected}."
      msg += " Updated #{result.cmd_tuples}."
      raise self.new(msg)
    end
  end

end
