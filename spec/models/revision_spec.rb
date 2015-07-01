require 'shared_examples/flaggable_examples.rb'

describe Revision do

  let(:flaggable){ create :revision, user:comment_creator, revisable:revisable }
  let(:comment_creator){ build_stubbed :user }
  let(:user){ build_stubbed :user}
  let(:default_status){Flaggable::NEEDS_REVIEW}

  describe 'owned by Drink' do
    let(:revisable){create :drink}
    include_examples 'flaggable'
  end

  describe 'owned by Ingredient' do
    let(:revisable){create :ingredient}
    include_examples 'flaggable'
  end

end
