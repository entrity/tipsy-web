CREATE FUNCTION flag_record
(s_table_name TEXT, i_user_id INT, i_flaggable_id INT, s_flaggable_type TEXT, i_flag_limit INT, i_flag_bits INT, i_flag_pts INT, s_description TEXT, dt_timestamp TIMESTAMP)
RETURNS TABLE (flag_created BOOLEAN, review_created BOOLEAN, flag_id INT) AS $$
  DECLARE duplicate_flag_ct INT;
  DECLARE open_review_ct INT;
  DECLARE aggregate_flagger_ids INT[];
  DECLARE contributor_id INT;
  DECLARE flag_pts_after_update INT;
  BEGIN
    -- check for existing flag with the same user and flaggable
    LOCK ONLY flags IN SHARE MODE;
    SELECT COUNT(*) FROM flags
      WHERE user_id = i_user_id
      AND flaggable_id = i_flaggable_id
      AND flaggable_type = s_flaggable_type
      LIMIT 1
      INTO duplicate_flag_ct;
    IF (SELECT duplicate_flag_ct) = 0 THEN
      -- create flag
      INSERT INTO flags (user_id, flaggable_id, flaggable_type, flag_bits, flag_pts, description, created_at) VALUES (i_user_id, i_flaggable_id, s_flaggable_type, i_flag_bits, i_flag_pts, s_description, dt_timestamp) RETURNING id INTO flag_id;
      -- increment flaggable's flag_pts
      EXECUTE FORMAT('UPDATE %s SET flag_pts = flag_pts + %s WHERE id = %s RETURNING flag_pts', s_table_name, i_flag_pts, i_flaggable_id) INTO flag_pts_after_update;
      -- set return value
      flag_created := TRUE;
      -- check whether flaggable exceeds FLAG_POINTS_LIMIT
      IF (flag_pts_after_update >= i_flag_limit) THEN
        -- check whether an open review exists for the flaggable
        LOCK ONLY reviews IN SHARE MODE;
        SELECT COUNT(*) FROM reviews
          WHERE open = TRUE
          AND reviewable_id = i_flaggable_id
          AND reviewable_type = s_flaggable_type
          LIMIT 1
          INTO open_review_ct;
        IF (SELECT open_review_ct) = 0 THEN
          -- calc aggregate flagger_ids
          SELECT ARRAY(SELECT user_id FROM flags WHERE flaggable_id = i_flaggable_id AND flaggable_type = s_flaggable_type) INTO aggregate_flagger_ids;
          -- get id of contributor whose contribution was flagged because this user is also not allowed to vote on the review to be created
          EXECUTE FORMAT('SELECT user_id FROM %s WHERE id = %s LIMIT 1', s_table_name, i_flaggable_id) INTO contributor_id;
          -- create review
          INSERT INTO reviews (reviewable_id, reviewable_type, open, contributor_id, flagger_ids, created_at)
            VALUES (
                i_flaggable_id,
                s_flaggable_type,
                TRUE,
                contributor_id,
                aggregate_flagger_ids,
                dt_timestamp
            );
          -- set return value
          review_created := TRUE;
        END IF;
      END IF;
    END IF;
    -- return
    RETURN NEXT;
  END;
$$ LANGUAGE plpgsql
