require 'rails_helper.rb'
require 'shared_examples/flaggable_examples.rb'

describe Revision do

  let(:flaggable){ create :revision, user:comment_creator, drink:drink }
  let(:drink){create :drink}
  let(:comment_creator){ build_stubbed :user }
  let(:user){ build_stubbed :user}
  let(:default_status){Flaggable::NEEDS_REVIEW}

  describe 'owned by Drink' do
    include_examples 'flaggable'
  end

  describe 'ingredients=' do
    let(:revision){Revision.new drink_id:1, user_id:1}
    let(:ingredients){build_list :drink_ingredient, 2}
    it 'sets persistable ingredients array' do
      expect(revision).to receive(:user).at_least(:once).and_return(user)
      expect(revision).to receive(:drink).at_least(:once).and_return(drink)
      revision.ingredients = ingredients
      revision.save
      revision.reload
      expect(revision.ingredients.length).to eq 2
    end
  end

end
