class InsertUniqueTrophy < ActiveRecord::Migration
  def up
    connection.execute %q(
      CREATE FUNCTION insert_unique_trophy (i_user_id INT, i_category_id INT)
      RETURNS BOOLEAN
      LANGUAGE plpgsql
      AS $$
      DECLARE i_duplicate_ct INT;
      BEGIN
        LOCK ONLY trophies IN SHARE MODE;
        SELECT COUNT(*) FROM trophies WHERE user_id = i_user_id AND category_id = i_category_id LIMIT 1 INTO i_duplicate_ct;
        IF (i_duplicate_ct = 0) THEN
          INSERT INTO trophies (user_id, category_id, created_at) VALUES (i_user_id, i_category_id, current_timestamp);
          RETURN TRUE;
        ELSE
          RETURN FALSE;
        END IF;
      END;
      $$;
    )
  end

  def down
    connection.execute "DROP FUNCTION insert_unique_trophy(INT, INT)"
  end
end
