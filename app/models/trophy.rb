class Trophy < ActiveRecord::Base
  belongs_to :user, inverse_of: :trophies

  after_create -> { user.increment_trophy_ct!(category.colour) }

  def category
    TrophyCategory::ALL[category_id]
  end

  def self.create_unique user, category
    res = connection.raw_connection.exec_params('SELECT * FROM insert_unique_trophy($1, $2)', [user.id, category.id])
    if res.getvalue(0,0) == 't'
      user.increment_trophy_ct!(category.colour)
      true
    else
      false
    end
  end

end
