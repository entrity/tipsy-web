class PointDistribution < ActiveRecord::Base
  belongs_to :user
  belongs_to :pointable, polymorphic: true

  Category = Struct.new(:id, :points, :message)

  def self.award user_id, pointable, category
    create! category_id:category.id, pointable:pointable, user_id:user_id, points:category.points
    res = connection.raw_connection.exec "UPDATE #{User.table_name} SET points = points + #{category.points} WHERE id = #{user_id}"
    unless res.cmd_tuples = 1
      raise "Failed to update user points correctly: user #{user_id}, category #{category.id}, cmd_tuples #{res.cmd_tuples}"
    end
  end

  def self.award_winning_vote user_id, pointable
    award user_id, pointable, WINNING_VOTE
  end

end
