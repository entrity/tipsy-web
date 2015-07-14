require 'rails_helper.rb'
require 'shared_examples/flaggable_examples.rb'

describe Revision do

  let(:flaggable){ create :revision, user:comment_creator, drink:drink }
  let(:drink){create :drink}
  let(:comment_creator){ build_stubbed :user }
  let(:user){ build_stubbed :user}
  let(:default_status){Flaggable::NEEDS_REVIEW}
  let(:revision){Revision.new drink_id:1, user_id:1}
  let(:ingredients){build_list :drink_ingredient, 2}

  describe 'owned by Drink' do
    include_examples 'flaggable'
  end

  describe 'ingredients=' do
    it 'sets persistable ingredients array' do
      expect(revision).to receive(:user).at_least(:once).and_return(user)
      expect(revision).to receive(:drink).at_least(:once).and_return(drink)
      revision.ingredients = ingredients
      revision.save
      revision.reload
      expect(revision.ingredients.length).to eq 2
    end
  end

  describe 'publish' do
    let(:user){build_stubbed :user}
    let(:drink){Drink.create(name:'foo')}
    let(:old_revision){create :revision, user:user, drink:drink}
    let(:new_revision){create :revision, user:user, base:old_revision, drink:drink, description:"and this way she will have to run", instructions:"and she can sing me away", ingredients:[{qty:'4pt', ingredient_id:235}, {qty:'5tsp', ingredient_id:123}], prep_time:'10min', calories:45}
    it 'updates the drink fields' do
      expect(drink.description).to be_nil
      expect(drink.instructions).to be_nil
      expect(drink.prep_time).to be_nil
      expect(drink.calories).to be_nil
      expect(drink.revision_id).to be_nil
      expect(drink.ingredient_ct).to eq 0
      expect(drink.ingredients).to be_empty
      old_revision.publish!
      drink.reload
      expect(drink.description).to eq("and this way she won't have to run away")
      expect(drink.instructions).to eq("and she can keep her regrets at bay")
      expect(drink.prep_time).to eq('10 min')
      expect(drink.calories).to eq(356)
      expect(drink.revision_id).to eq(old_revision.id)
      expect(drink.ingredients.reload.length).to eq(2)
      new_revision.publish!
      drink.reload
      expect(drink.description).to eq("and this way she will have to run")
      expect(drink.instructions).to eq("and she can sing me away")
      expect(drink.prep_time).to eq('10min')
      expect(drink.calories).to eq(45)
      expect(drink.revision_id).to eq(new_revision.id)
      expect(drink.ingredients.reload.length).to eq(2)
    end
  end

end
