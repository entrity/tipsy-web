class Favourite < ActiveRecord::Base
  belongs_to :user
  belongs_to :drink
  belongs_to :collection, class_name: 'FavouritesCollection'
  has_one    :photo, through: :drink

  validates :user, presence: true, uniqueness: {scope: [:drink_id, :collection_id]}
  validates :drink, presence: true

  delegate :name, to: :drink, allow_nil: true

  def preview_url
    photo && photo.file.url(:medium)
  end

end
