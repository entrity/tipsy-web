class FavouritesCollection < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true
  validates :name, presence: true, uniqueness: {scope: :user_id}

  has_many :favourites

  def infer_preview_urls!
    res = self.class.connection.execute %Q(SELECT photos.*
      FROM favourites
        INNER JOIN drinks ON favourites.drink_id = drinks.id
        LEFT OUTER JOIN photos ON drinks.id = photos.drink_id
        WHERE favourites.collection_id = #{id}
        ORDER BY drinks.score DESC, photos.score DESC
        LIMIT 4
    )
    urls = res.to_a.map do |row|
      photo = Photo.new(row)
      photo.instance_variable_set('@new_record', false) # hack to make this look like a persisted record. without it, paperclip returns nil for an attachment url
      photo.file.url(:thumb)
    end
    update_attributes! preview_urls:urls
  end

  def preview_drink_id= id
    photo = Photo.where(drink_id:id).order(:score).last
    self.preview_url = photo.file.url(:medium) if photo
  end

end
