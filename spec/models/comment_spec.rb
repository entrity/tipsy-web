require 'rails_helper.rb'
require 'shared_examples/flaggable_examples.rb'

describe Comment do

  let(:flaggable){ create :comment, user:comment_creator }
  let(:comment_creator){ build_stubbed :user }
  let(:user){ build_stubbed :user}
  let(:default_status){Flaggable::APPROVED}

  include_examples 'flaggable'

end
