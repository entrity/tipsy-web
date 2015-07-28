class CreateExtensionFuzzystrmatch < ActiveRecord::Migration
  def change
    execute 'CREATE EXTENSION IF NOT EXISTS fuzzystrmatch'
  end
end
