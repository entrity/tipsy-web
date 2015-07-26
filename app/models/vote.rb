class Vote < ActiveRecord::Base
  belongs_to :user
  belongs_to :votable, polymorphic: true

  scope :for_user_photos_comments_drink, -> user_id, photo_ids, comment_ids, drink_id {
    conditions = ["(votable_type = 'Drink' AND votable_id = %d)" % drink_id]
    conditions.push("(votable_type = 'Photo' AND votable_id IN (%s))" % photo_ids.join(',')) if photo_ids.present?
    conditions.push("(votable_type = 'Comment' AND votable_id IN (%s))" % comment_ids.join(',')) if comment_ids.present?
    stmt = "user_id = %d AND (%s)" % [user_id, conditions.join(' OR ')]
    where(stmt)
  }

  validates :user, presence: true
  validates :votable, presence: true
  validates :sign, presence: true

  def save
    if valid?
      self.sign = sign <=> 0 # ensure sign is in {-1,0,1}
      conn = self.class.connection.raw_connection
      res = conn.exec_params "SELECT * FROM create_or_update_vote($1, $2, $3, $4) AS vote_id", [user_id, votable_id, votable_type, sign]
      unless res.cmd_tuples == 1
        errors.add :base, "has unspecified error. cmd_tuples is #{res.cmd_tuples}"
      end
      results_hash = res.to_a.first
      self[:id] = results_hash['vote_id']
      # update score of votable
      if self.id
        raise TipsyException, "No 'prev_sign' in result from create_of_update_vote" unless results_hash.has_key?('prev_sign')
        delta = sign - (results_hash['prev_sign'].to_i <=> 0) # should be in {-1,0,1}
        votable.increment_score!(delta) if delta != 0
      end
      # return
      true
    else
      false
    end
  end
end
