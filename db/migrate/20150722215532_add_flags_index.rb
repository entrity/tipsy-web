class AddFlagsIndex < ActiveRecord::Migration
  def change
    add_index :flags, [:user_id, :flaggable_id, :flaggable_type], name: 'index_flags'
  end
end
