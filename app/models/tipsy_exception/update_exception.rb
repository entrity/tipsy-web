class TipsyException::UpdateException < TipsyException::Exception

  # @param response - a PG::Result (return value from PG::Connection.execute)
  # @param expected - number of rows expected to be updated in UPDATE command
  def self.assert_update_count(response, expected)
    unless response.cmd_tuples == expected
      msg = "Incorrect number of rows updated in UPDATE command."
      msg += " Expected #{expected}."
      msg += " Updated #{response.cmd_tuples}."
      raise self.new(msg)
    end
  end

end
