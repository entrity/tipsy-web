require 'rails_helper.rb'
require 'shared_examples/flaggable_examples.rb'

describe Comment do

  let(:flaggable){ create :comment, user:comment_creator, drink:drink }
  let(:comment_creator){ build_stubbed :user }
  let(:user){ build_stubbed :user}
  let(:drink){ build_stubbed :drink}
  let(:default_status){Flaggable::APPROVED}

  include_examples 'flaggable'

end
