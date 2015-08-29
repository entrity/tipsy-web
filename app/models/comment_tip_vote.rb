class CommentTipVote < ActiveRecord::Base
  belongs_to :user
  belongs_to :comment

  validates :user, presence: true, uniqueness: {scope: :comment_id}
  validates :comment, presence: true

  after_create -> { comment.pg_increment!(:tip_pts) }
  
  after_destroy -> { comment.pg_increment!(:tip_pts, -1) }

end
