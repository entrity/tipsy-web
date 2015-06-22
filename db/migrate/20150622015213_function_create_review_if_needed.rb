class FunctionCreateReviewIfNeeded < ActiveRecord::Migration
  def up
    execute %Q(
      CREATE FUNCTION create_review_if_needed (IN table_name TEXT, IN rec_id INT, IN rec_type TEXT)
      RETURNS boolean AS $$
      DECLARE flag_pts INT;
      BEGIN
        LOCK TABLE #{Review.table_name};
        EXECUTE format('SELECT flag_pts FROM %I WHERE id = %L', $1, $2) INTO flag_pts;
        IF
          flag_pts >= #{Flaggable::FLAG_PTS_LIMIT}
        AND
          (
            SELECT open FROM "#{Review.table_name}"
            WHERE reviewable_id = $2 AND reviewable_type = $3
          ) IS NOT TRUE
        THEN
          INSERT INTO "#{Review.table_name}"
          (reviewable_id, reviewable_type, open)
          VALUES ($2, $3, TRUE);
          RETURN TRUE;
        END IF;
        RETURN FALSE;
      END
      $$ LANGUAGE plpgsql
    )
  end

  def down
    execute "DROP FUNCTION create_review_if_needed(TEXT, INT, TEXT)"
  end
end
