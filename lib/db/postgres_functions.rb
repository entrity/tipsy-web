module PostgresFunctions

  def create_flag_fn(table_name, overwrite=false)
    raw_connection.exec %Q(
      CREATE #{overwrite ? 'OR REPLACE' : nil} FUNCTION flag_#{table_name}
      (i_user_id INT, i_flaggable_id INT, s_flaggable_type TEXT, i_flag_limit INT, i_flag_bits INT, i_flag_pts INT, dt_timestamp TIMESTAMP)
      RETURNS INT AS $$
        DECLARE duplicate_flag_ct INT;
        DECLARE open_review_ct INT;
        DECLARE aggregate_flagger_ids INT[];
        DECLARE return_value INT := #{Flaggable::DB_INITIAL};
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
            INSERT INTO flags (user_id, flaggable_id, flaggable_type, flag_bits, flag_pts, created_at) VALUES (i_user_id, i_flaggable_id, s_flaggable_type, i_flag_bits, i_flag_pts, dt_timestamp);
            -- increment flaggable's flag_pts
            UPDATE #{table_name} SET flag_pts = flag_pts + i_flag_pts WHERE id = i_flaggable_id;
            -- set return value
            return_value := #{Flaggable::DB_FLAG_INSERTED};
            -- check whether flaggable exceeds FLAG_POINTS_LIMIT
            IF ((SELECT flag_pts FROM #{table_name} WHERE id = i_flaggable_id) >= i_flag_limit) THEN
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
                -- create review
                INSERT INTO reviews (reviewable_id, reviewable_type, open, contributor_id, flagger_ids, created_at)
                  VALUES (
                      i_flaggable_id,
                      s_flaggable_type,
                      TRUE,
                      (SELECT user_id FROM #{table_name} WHERE id = i_flaggable_id LIMIT 1),
                      aggregate_flagger_ids,
                      dt_timestamp
                  );
                return_value := #{Flaggable::DB_REVIEW_INSERTED};
              END IF;
            END IF;
          END IF;
          RETURN return_value;
        END;
      $$ LANGUAGE plpgsql
    )
  end

  def drop_flag_fn(table_name, strict=false)
    raw_connection.exec "DROP FUNCTION #{strict ? nil : 'IF EXISTS'} flag_#{table_name}(i_user_id INT, i_flaggable_id INT, s_flaggable_type TEXT, i_flag_limit INT, i_flag_bits INT, i_flag_pts INT, dt_timestamp TIMESTAMP)"
  end

  def raw_connection
    ActiveRecord::Base.connection.raw_connection
  end

end