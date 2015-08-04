class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :confirmable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauth_providers => [:facebook]

  has_many :identities, inverse_of: :user
  has_many :photos, inverse_of: :user # contributions. photos of drinks
  has_many :review_votes, inverse_of: :user
  has_many :revisions, as: :user
  has_many :trophies, inverse_of: :user

  has_attached_file :photo, :styles => { :thumb => "128x128>", :tiny => "32x32>" }, :default_url => '/images/anonymous-:style.jpg'

  validates :nickname, uniqueness: true, allow_blank: true, format: { with: /[a-zA-Z]/,
    message: "requries at least one alphabetic character" }
  validates_with AttachmentContentTypeValidator, :attributes => :photo, :content_type => ["image/jpeg", "image/png"]
  validates_with AttachmentSizeValidator, :attributes => :photo, :less_than => 5.megabytes
  validates_attachment_file_name :photo, :matches => [/png\Z/, /jpe?g\Z/]

  after_update :award_trophies_on_update

  # @return order of magnitude of `self.points`
  def log_points
    Math.log([1 + points, 2].max, 10).ceil
  end

  def self.from_omniauth(auth, signed_in_resource=nil)
    # Get the identity and user if they exist
    identity = Identity.from_omniauth(auth)

    # If a signed_in_resource is provided it always overrides the existing user
    # to prevent the identity being locked with accidentally created accounts.
    # Note that this may leave zombie accounts (with no associated identity) which
    # can be cleaned up at a later date.
    user = signed_in_resource ? signed_in_resource : identity.user
    
    # Create the user if needed
    if user.nil?
      # Get the existing user by email if the provider gives us a verified email.
      # If no verified email was provided we assign a temporary email and ask the
      # user to verify it on the next step via UsersController.finish_signup
      email_is_verified = auth.info.email && (auth.info.verified || auth.info.verified_email)
      email = auth.info.email if email_is_verified
      user = User.where(:email => email).first if email

      # Create the user if it's a new registration
      if user.nil?
        name = nil
        begin
          auth.info.nickname || auth.extra.raw_info.name || auth.uid
        rescue => ex
        end
        user = User.new(
          name: name,
          email: email,
          password: Devise.friendly_token[0,20]
        )
        user.skip_confirmation!
        user.save!
      end
    end

    # Associate the identity with the user if needed
    if identity.user != user
      identity.user = user
      identity.save!
    end
    user
  end

  def increment_comment_ct!
    award_trophy case pg_increment!(:comment_ct)
    when 1;   TrophyCategory::COMMENTS_1
    when 20;  TrophyCategory::COMMENTS_20
    when 75;  TrophyCategory::COMMENTS_75
    when 200; TrophyCategory::COMMENTS_200
    end
  end

  def increment_helpful_flag_ct!
    award_trophy case flag.user.pg_increment!(:helpful_flags)
    when 5;  TrophyCategory::HELPFUL_FLAGS_5
    when 15; TrophyCategory::HELPFUL_FLAGS_15
    when 50; TrophyCategory::HELPFUL_FLAGS_50
    end
  end

  # Increment count, award trophy
  def increment_majority_votes!
    award_trophy case pg_increment!(:majority_review_votes)
    when 1;   TrophyCategory::WINNING_VOTES_1
    when 10;  TrophyCategory::WINNING_VOTES_10
    when 50;  TrophyCategory::WINNING_VOTES_50
    when 250; TrophyCategory::WINNING_VOTES_250
    end
  end

  # Increment count
  def increment_minority_votes!
    pg_increment!(:minority_review_votes)
  end
  
  def increment_photo_ct!
    award_trophy case pg_increment!(:photo_ct)
    when 1;   TrophyCategory::PHOTOS_1
    when 20;  TrophyCategory::PHOTOS_20
    when 75;  TrophyCategory::PHOTOS_75
    when 200; TrophyCategory::PHOTOS_200
    end
  end
  
  def increment_revision_ct!
    award_trophy case pg_increment!(:revision_ct)
      when 1;  TrophyCategory::REVISIONS_1
      when 10; TrophyCategory::REVISIONS_10
      when 25; TrophyCategory::REVISIONS_25
      when 75; TrophyCategory::REVISIONS_75
    end
  end

  # @param colour - integer
  def increment_trophy_ct! colour
    pg_increment! case colour
    when TrophyCategory::GOLD
      :gold_trophy_ct
    when TrophyCategory::SILVER
      :silver_trophy_ct
    when TrophyCategory::BRONZE
      :bronze_trophy_ct
    end
  end

  def increment_unhelpful_flag_ct!
    award_trophy case pg_increment!(:unhelpful_flags)
    when 5; TrophyCategory::BAD_FLAGS_5
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  # @param hash should contain :data_url & :filename
  def photo_data= hash
    raise "No data_url in photo_data" unless hash[:data_url].present?
    raise "No filename in photo_data" unless hash[:filename].present?
    image = Paperclip.io_adapters.for(hash[:data_url])
    image.original_filename = hash[:filename]
    self.photo = image
  end

  def photo_url
    photo.url
  end

  # @override
  def serializable_hash(options={})
    options[:methods] ||= [:photo_url]
    super(options)
  end

  def url_path
    if nickname.present?
      "/users/#{nickname.to_s.downcase.gsub(/[\W]+/, '-')}"
    else
      "/users/#{id}"
    end
  end

  private

    def award_trophy trophy_category
      Trophy.create(user:self, category_id:trophy_category.id) if trophy_category
    end

    def award_trophies_on_update
      if changes['no_profanity'] && changes['no_profanity'][1] && 
        Trophy.create_unique(self, TrophyCategory::NO_PROFANITY)
      end
      if changes['no_alcohol'] && changes['no_alcohol'][1]
        Trophy.create_unique(self, TrophyCategory::NO_ALCOHOL)
      end
    end

end
