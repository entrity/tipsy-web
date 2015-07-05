class Review < ActiveRecord::Base
  POINTS_TO_CLOSE = 4

  belongs_to :contributor, class_name: 'User'
  belongs_to :reviewable, polymorphic: true

  validates :contributor, presence: true

  default_scope { where(open:true) }

  scope :open, -> user { where(open:true).where('contributor_id != ?', user.id).where('NOT (? = ANY(flagger_ids))', user.id) }

  def diff
    base = reviewable.try(:base)
    diff = Hash.new
    if base
      reviewable.attributes.each do |key, curval|
        prev = base[key]
        if curval.is_a? Array
          diff[key] = prev
        else
          diff[key] = Diffy::Diff.new(prev.to_s, curval.to_s).to_s(:html)
        end
      end
    end
    diff
  end

  # Returns a Review if successful, else nil
  def self.next! user
    res = connection.raw_connection.exec_params(%Q(UPDATE #{table_name} topquery
      SET last_hold = current_timestamp, last_hold_user_id = $2
      FROM (
        SELECT id FROM reviews
        WHERE last_hold IS NULL OR last_hold < $1 OR last_hold_user_id = $2
        AND open IS TRUE
        AND contributor_id != $2
        AND NOT $2 = ANY(flagger_ids)
        LIMIT 1
        FOR UPDATE
      ) subquery
      WHERE topquery.id = subquery.id
      RETURNING *),
    [5.minutes.ago, user.id])
    if res.cmd_tuples == 1
      Review.new(res.first)
    end
  end

  def vote! vote
    # Update points and open fields
    conn = self.class.connection.raw_connection
    conn.exec_params(
      %Q(UPDATE #{self.class.table_name}
        SET
          points = points + $1,
          open = points + $1 < abs(#{POINTS_TO_CLOSE}),
          flagger_ids = array_append(flagger_ids, $3) 
        WHERE id = $2), [vote.points, id, vote.user_id]
    )
    # If this Review is closed, set status of reviewable
    unless reload.open
      status = points <=> 0
      reviewable.update_attributes! status:status
    end
  end

end
