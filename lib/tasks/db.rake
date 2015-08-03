namespace :db do
  task :load_ingredients => :environment do
    require 'csv'
    CANONICAL_HEADER = 'canonical alias'
    NAME_HEADER      = 'name'
    ID_HEADER        = 'id'
    db = ActiveRecord::Base.connection.raw_connection
    CSV.foreach 'db/ingredients.csv', headers: true do |row|
      h = row.to_h
      id = h[ID_HEADER].present? && h[ID_HEADER].to_i
      if id
        canonical_id = h[CANONICAL_HEADER].present? ? h[CANONICAL_HEADER].to_i : id
        name         = h[NAME_HEADER]
        byebug if name.blank?
        db.exec_params "UPDATE ingredients SET name = $1, canonical_id = $2 WHERE id = $3", [name, canonical_id, id]
      end
    end
  end
end
