module Votable

  def self.included(base)
    unless base.attribute_method?(:score)
      raise "No score column on Votable class #{base.name}"
    end
    base.has_many :votes, as: :votable, dependent: :destroy, inverse_of: :votable
  end

  def increment_score!(delta)
    conn = self.class.connection.raw_connection
    res = conn.exec "UPDATE #{self.class.table_name} SET score = score + #{delta} WHERE id = #{id}"
    TipsyException::DatabaseException.assert_row_count(res, 1, 'UPDATE')
  end

end
