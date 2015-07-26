class PointDistribution < ActiveRecord::Base
  belongs_to :user
  belongs_to :pointable, polymorphic: true

  def self.award user_id, pointable, category, options={}
    options[:user_id]         = user_id
    options[:pointable]       = pointable
    if category
      options[:category_id]   = category.id
      options[:description] ||= category.message
      options[:points]      ||= category.points
    end
    create!(options)
    res = connection.raw_connection.exec "UPDATE #{User.table_name} SET points = points + #{category.points} WHERE id = #{user_id}"
    TipsyException::DatabaseException.assert_row_count(res, 1, 'UPDATE')
  end

  # Award points for user participating in winning side of Review voting
  def self.award_winning_vote user_id, pointable
    award user_id, pointable, PointDistributionCategory::WINNING_VOTE
  end

end
