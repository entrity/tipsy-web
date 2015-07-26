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

  def distribute_vote_points(prev_sign, sign)
    up_cat, dn_cat = case self
    when Comment
      [PointDistributionCategory::COMMENT_UPVOTE, PointDistributionCategory::COMMENT_DOWNVOTE]
    when Photo
      [PointDistributionCategory::PHOTO_UPVOTE, PointDistributionCategory::PHOTO_DOWNVOTE]
    end
    if prev_sign < 0 # need to undistribute points from previous upvote
      award_single_point_distribution(up_cat, true)
    elsif prev_sign > 0 # need to undistribute points form previous dnvote
      award_single_point_distribution(dn_cat, true)
    end
    if sign < 0 # need to distribute points for dnvote
      award_single_point_distribution(dn_cat, false)
    elsif sign > 0 # need to distribute points for upvote
      award_single_point_distribution(up_cat, false)
    end
  end

  private

    def award_single_point_distribution(category, negative)
      points = category.points
      description = category.message
      if negative
        points *= -1
        description += " - UNDONE"
      end
      PointDistribution.award(user_id, self, category,
        points: points,
        title: drink.name,
        description: description,
        url: drink.url_path,
      )
    end

end
