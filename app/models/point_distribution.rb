class PointDistribution < ActiveRecord::Base
  belongs_to :user

  Category = Struct.new(:id, :points, :message)

  def self.award user_id, category
    create! category_id:category.id, user_id:user_id, points:category.points
    res = connection.raw_connection.exec "UPDATE #{User.table_name} SET points = points + #{category.points} WHERE id = #{user_id}"
    unless res.cmd_tuples = 1
      raise "Failed to update user points correctly: user #{user_id}, category #{category.id}, cmd_tuples #{res.cmd_tuples}"
    end
  end

  def self.award_winning_vote user_id
    award user_id, WINNING_VOTE
  end

end
