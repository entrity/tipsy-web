class FavouritesCollection < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true
  validates :name, presence: true, uniqueness: {scope: :user_id}

  def preview_drink_id= id
    photo = Photo.where(drink_id:id).order(:score).last
    self.preview_url = photo.file.url(:medium) if photo
  end

end
