class Comment < ActiveRecord::Base
  include Flaggable

  belongs_to :user
  belongs_to :commentable, polymorphic: true

end
