class DeleteScrapedInstructions < ActiveRecord::Migration
  def up
    execute 'update drinks set instructions = NULL'
    execute 'update ingredients set name = replace(name, \'&reg;\', U&\'\00ae\') where name ~ \'&reg;\''
  end
end
