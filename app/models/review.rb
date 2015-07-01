class Review < ActiveRecord::Base
  POINTS_TO_CLOSE = 4

  belongs_to :reviewable, polymorphic: true

  default_scope { where(open:true) }

  def vote! points
    # Update points and open fields
    conn = self.class.connection.raw_connection
    conn.exec_params(
      %Q(UPDATE #{self.class.table_name}
        SET
          points = points + $1,
          open = points + $1 > abs(#{VOTE_REQUIREMENT})
        WHERE id = $2), [points, id]
    )
    # If this Review is closed, set status of reviewable
    unless reload.open
      status = points <=> 0
      reviewable.update_attributes! status:status
    end
  end

end
