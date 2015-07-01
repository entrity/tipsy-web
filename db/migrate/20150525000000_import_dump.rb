class ImportDump < ActiveRecord::Migration
  def up
    %x(env bash db/convert_scrape_to_postgres.sh #{connection.current_database})
  end
end
