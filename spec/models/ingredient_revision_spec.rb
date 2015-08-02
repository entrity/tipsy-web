require 'rails_helper.rb'

describe Revision do

  let(:ingredient){Ingredient.create(name:'foo')}
  let(:user){build_stubbed :user}

  describe 'publish!' do
    let(:old_revision){create :ingredient_revision, user:user, ingredient:ingredient}
    let(:new_revision){create :ingredient_revision, user:user, parent:old_revision, ingredient:ingredient, description:"they grew to the steeple"}
    before do
      allow(user).to receive(:increment_revision_ct!).and_return(true)
    end
    it 'updates the ingredient fields' do
      expect(ingredient.description).to be_nil
      expect(ingredient.revision_id).to be_nil
      old_revision.publish!
      expect(ingredient.description).to eq("they grew and grew")
      expect(ingredient.revision_id).to eq(old_revision.id)
      new_revision.publish!
      ingredient.reload
      expect(ingredient.description).to eq("they grew to the steeple")
      expect(ingredient.revision_id).to eq(new_revision.id)
    end
  end

  describe 'unpublish!' do
    before do
      allow(user).to receive(:increment_revision_ct!).and_return(true)
    end
    let(:rev_1){IngredientRevision.create ingredient:ingredient, user:user, name:'Ronnie', description:"foo bar\nbaz qux"}
    let(:rev_2){IngredientRevision.create ingredient:ingredient, user:user, name:'James',  description:"foo far\nbaz\nqux"}
    let(:rev_3){IngredientRevision.create ingredient:ingredient, user:user, name:'Dio',    description:"foo far\nqux"}
    it 'reverse-patches description and instructions on ingredient' do
      rev_1.publish!
      rev_2.publish!
      rev_3.publish!
      ingredient.reload
      expect(ingredient.name).to eq 'Dio'
      expect(ingredient.description).to eq rev_3.description
      rev_2.unpublish!
      expect(ingredient.name).to eq 'Dio'
      expect(ingredient.description).to eq "foo bar\n qux"
      expect(ingredient.revision_id).to eq(rev_3.id)
    end
  end

end
