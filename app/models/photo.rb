class Photo < ActiveRecord::Base
  include Flaggable
  include Votable

  belongs_to :drink, inverse_of: :photos
  belongs_to :user, inverse_of: :photos

  has_attached_file :file, :styles => { :large => "1060", :medium => "400x400>", :thumb => "100x66>" }

  validates_with AttachmentPresenceValidator, :attributes => :file
  validates_with AttachmentContentTypeValidator, :attributes => :file, :content_type => ["image/jpeg", "image/png"]
  validates_with AttachmentSizeValidator, :attributes => :file, :less_than => 10.megabytes
  validates_attachment_file_name :file, :matches => [/\.png\Z/i, /\.jpe?g\Z/i]
  validates :drink, presence: true
  validates :user,  presence: true

  def medium_url
    file.url(:medium)
  end

  def publish!
    super
    user.increment_photo_ct!
  end
  
  # @override
  def serializable_hash(options={})
    options[:methods] ||= [:url]
    super(options)
  end

  def thumb
    file.url(:thumb)
  end

  def url
    file.url
  end

end
