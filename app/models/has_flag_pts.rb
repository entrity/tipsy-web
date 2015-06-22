module HasFlagPts

  def self.included(base)
    unless base.attribute_method?(:flag_pts)
      raise "No flag_pts column on class #{base.name}"
    end
    unless base.attribute_method?(:flagger_ids)
      raise "No flagger_ids column on class #{base.name}"
    end
  end
  
  def increment_flag_points!(points, flagger_id)
    raise TipsyException.new("Non-positive flag points #{flagger_id} #{points}") unless points > 0
    conn = self.class.connection.raw_connection
    res = conn.exec_params(
      %Q(UPDATE #{self.class.table_name}
        SET
          flag_pts = flag_pts + $1,
          flagger_ids = array_append(flagger_ids, $2)
        WHERE id = $3
        AND NOT ($2 = ANY(flagger_ids))), [points, flagger_id, id]
    )
    # Raise error if more or fewer than one row updated
    TipsyException::UpdateException.assert_update_count(res, 1)
    self.flag_pts += points
    self.flagger_ids << flagger_id
    res
  end

end
