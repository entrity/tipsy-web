class AddCreateOrUpdateVoteFn < ActiveRecord::Migration
  def up
    connection.execute %Q(
      CREATE FUNCTION create_or_update_vote
      (i_user_id INT, i_votable_id INT, s_votable_type TEXT, i_sign INT)
      RETURNS TABLE (vote_id INT, prev_sign INT)
      AS $$
      BEGIN
        LOCK ONLY votes IN SHARE MODE;
        SELECT id, sign FROM votes
          WHERE user_id = i_user_id AND votable_id = i_votable_id AND votable_type = s_votable_type
          LIMIT 1
          INTO vote_id, prev_sign;
        IF (vote_id IS NOT NULL) THEN
          UPDATE votes SET sign = i_sign, updated_at = current_timestamp
            WHERE user_id = i_user_id AND votable_id = i_votable_id AND votable_type = s_votable_type;
        ELSE
          prev_sign := 0;
          INSERT INTO votes (user_id, votable_id, votable_type, sign, created_at, updated_at)
            VALUES (i_user_id, i_votable_id, s_votable_type, i_sign, current_timestamp, current_timestamp)
            RETURNING id INTO vote_id;
        END IF;
        RETURN NEXT;
      END;
      $$ LANGUAGE plpgsql
    )
  end

  def down
    connection.execute "DROP FUNCTION create_or_update_vote (INT, INT, TEXT, INT)"
  end
end
