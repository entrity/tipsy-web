namespace :db do
  task :load_ingredients => :environment do
    require 'csv'
    CANONICAL_HEADER = 'canonical alias'
    NAME_HEADER      = 'name'
    ID_HEADER        = 'id'
    CSV.foreach 'db/ingredients.csv', headers: true do |row|
      h = row.to_h
      id = h[ID_HEADER].present? && h[ID_HEADER].to_i
      if id
        canonical_id = h[CANONICAL_HEADER].present? ? h[CANONICAL_HEADER].to_i : id
        name         = h[NAME_HEADER]
        raise "No name!: #{row.inspect}" if name.blank?
        res = db.exec_params "UPDATE ingredients SET name = $1, canonical_id = $2 WHERE id = $3", [name, canonical_id, id]
        if res.cmd_tuples == 0
          db.exec_params "INSERT INTO ingredients (id, name, canonical_id) VALUES ($1, $2, $3)", [id, name, canonical_id]
        end
      end
    end
  end

  task :set_required_ingredients => :environment do
    db.exec "UPDATE drinks SET required_canonical_ingredient_ids = (SELECT ARRAY_AGG(ingredients.canonical_id) FROM ingredients INNER JOIN drinks_ingredients ON ingredient_id = ingredients.id WHERE drink_id = drinks.id)"
  end

  task :find_bad_canonical_ids => :environment do
    res = db.exec "SELECT i.id, i.name, i.canonical_id from ingredients as i left outer join ingredients as ii on i.canonical_id = ii.id where ii.id is null or ii.id != ii.canonical_id;"
    if res.count == 0
      puts "[OK]"
    else
      res.each{|x| puts x }
      fail "[FAILED]"
    end
  end

  def db
    ActiveRecord::Base.connection.raw_connection
  end
end
