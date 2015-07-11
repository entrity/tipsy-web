require 'rails_helper.rb'
# require 'spec_helper.rb'

describe RevisionsController, type: :controller do

  before do
      # @request.env["devise.mapping"] = Devise.mappings[:user]
    # sign_in FactoryGirl.create(:user)
    # binding.pry
    @user = FactoryGirl.create(:user)
    @user.confirm!
    sign_in @user
  end

  describe 'create' do
    let(:params){{
      "name"=>"Valentined",
      "description"=>nil,
      "instructions"=>nil,
      "ingredients"=>[
        {"drink_id"=>11262, "ingredient_id"=>593, "qty"=>"3 ", "optional"=>false, "name"=>"vanilla"},
        {"drink_id"=>11262, "ingredient_id"=>30, "qty"=>"1 oz", "optional"=>true, "name"=>"milk"},
        {"drink_id"=>11262, "ingredient_id"=>104, "qty"=>"3/2 oz", "optional"=>false, "name"=>"Bailey's® Irish cream"},
        {"drink_id"=>11262, "ingredient_id"=>491, "qty"=>"3 tbsp", "optional"=>false, "name"=>"strawberry puree"},
        {"ingredient_id"=>40, "qty"=>"3/4 oz", "optional"=>true}
      ],
      "abv"=>3,
      "calories"=>nil,
      "prep_time"=>nil,
      "profane"=>false,
      "non_alcoholic"=>false,
      "drink_id"=>11262,
      "revision_id"=>nil,
      "drink_description"=>nil,
      "drink_instruction"=>nil,
      "drink_ingredients"=>[
        {"drink_id"=>11262, "ingredient_id"=>593, "qty"=>"3 ", "optional"=>false, "name"=>"vanilla"},
        {"drink_id"=>11262, "ingredient_id"=>30, "qty"=>"1 oz", "optional"=>false, "name"=>"milk"},
        {"drink_id"=>11262, "ingredient_id"=>104, "qty"=>"1/2 oz", "optional"=>false, "name"=>"Bailey's® Irish cream"},
        {"drink_id"=>11262, "ingredient_id"=>249, "qty"=>"1/2 ozWhite", "optional"=>false, "name"=>"cocoa"},
        {"drink_id"=>11262, "ingredient_id"=>38, "qty"=>"3/4 oz", "optional"=>false, "name"=>"Malibu® coconut rum"},
        {"drink_id"=>11262, "ingredient_id"=>491, "qty"=>"3 tbsp", "optional"=>false, "name"=>"strawberry puree"}
      ],
      "revision"=>{"drink_id"=>11262, "instructions"=>nil, "name"=>"Valentined", "description"=>nil, "prep_time"=>nil, "calories"=>nil, "non_alcoholic"=>false, "profane"=>false, "ingredients"=>[{"drink_id"=>11262, "ingredient_id"=>593, "qty"=>"3 ", "optional"=>false, "name"=>"vanilla"}, {"drink_id"=>11262, "ingredient_id"=>30, "qty"=>"1 oz", "optional"=>true, "name"=>"milk"}, {"drink_id"=>11262, "ingredient_id"=>104, "qty"=>"3/2 oz", "optional"=>false, "name"=>"Bailey's® Irish cream"}, {"drink_id"=>11262, "ingredient_id"=>491, "qty"=>"3 tbsp", "optional"=>false, "name"=>"strawberry puree"}, {"ingredient_id"=>40, "qty"=>"3/4 oz", "optional"=>true}]},
      "format" => "json",
    }}
    it 'sets prev_ingredients' do
      expect_any_instance_of(Revision).to receive(:drink).at_least(:once).and_return(build_stubbed :drink)
      post :create, params
      r = Revision.last
      expect(response.status).to eq 201
    end
  end

end
