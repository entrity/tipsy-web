module Votable

  def self.included(base)
    unless base.attribute_method?(:score)
      raise "No score column on Votable class #{base.name}"
    end
    unless base.attribute_method?(:user_id)
      raise "No user_id column on Votable class #{base.name}"
    end
    base.has_many :votes, as: :votable, dependent: :destroy, inverse_of: :votable
  end

  def create_trophy_if_warranted
    case self
    when Comment
      case score
      when -4
        Trophy.create(user:user, category_id:TropyCategory::COMMENT_NEGATIVE_4_POINTS.id)
      when 3
        Trophy.create(user:user, category_id:TropyCategory::COMMENT_3_POINTS.id)
      when 8
        Trophy.create(user:user, category_id:TropyCategory::COMMENT_8_POINTS.id)
      when 20
        Trophy.create(user:user, category_id:TropyCategory::COMMENT_20_POINTS.id)
      end
    when Photo
      case score
      when -2
        Trophy.create(user:user, category_id:TropyCategory::COMMENT_NEGATIVE_2_POINTS.id)
      when 5
        Trophy.create(user:user, category_id:TropyCategory::COMMENT_5_POINTS.id)
      when 13
        Trophy.create(user:user, category_id:TropyCategory::COMMENT_13_POINTS.id)
      when 30
        Trophy.create(user:user, category_id:TropyCategory::COMMENT_30_POINTS.id)
      end
    when Drink
      case user && score
      when 5
        Trophy.create(user:user, category_id:TropyCategory::DRINK_5_POINTS.id)
      when 15
        Trophy.create(user:user, category_id:TropyCategory::DRINK_15_POINTS.id)
      when 50
        Trophy.create(user:user, category_id:TropyCategory::DRINK_50_POINTS.id)
      end
    end
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
    when Drink
      user && [PointDistributionCategory::DRINK_UPVOTE, PointDistributionCategory::DRINK_DOWNVOTE]
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
      return unless category
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
