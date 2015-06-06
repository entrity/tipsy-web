require 'shared_examples/drinks_or_ingredients_controller.rb'

describe DrinksController, :type => :controller do

  let(:drink) { build_stubbed :drink, id:1, name:'tom collins', description:'foo', instructions:'bar', ingredients:drink_ingredients }
  let(:drink_ingredients) { build_list :drink_ingredient, 3 }

  include_examples 'drinks or ingredients controller'

  describe '#show' do
    context 'with html format' do
      it 'should return 200' do 
        expect(controller).to receive(:saved_drink).at_least(:once).and_return(drink)
        get :show, id: 1, format: :html
        assert_response 200
      end
    end
    context 'with json format' do
      it 'should return 200' do 
        expect(controller).to receive(:saved_drink).at_least(:once).and_return(drink)
        get :show, id: 1, format: :json
        assert_response 200
      end
    end
  end

  describe '#index' do
    subject{ get :index, params }
    context 'with json format' do
      let(:params){{format: :json}}
      context 'with ingredient_id[] param' do
        it 'should return 200' do
          expect_any_instance_of(ActiveRecord::Relation).to receive(:joins).with(:ingredients).and_call_original
          params[:ingredient_id] = 1
          subject
          assert_response 200
        end
      end
      context 'with ingredient_id[] param' do
        context 'of multiple values' do
          it 'should return 200' do
            expect_any_instance_of(ActiveRecord::Relation).to receive(:joins).with(:ingredients).and_call_original
            params[:ingredient_id] = [1,2,3]
            subject
            assert_response 200
          end
        end
        context 'of one value' do
          it 'should return 200' do
            expect_any_instance_of(ActiveRecord::Relation).to receive(:joins).with(:ingredients).and_call_original
            params[:ingredient_id] = [1]
            subject
            assert_response 200
          end
        end
      end
      context 'with select[] param of :ingredient_ct' do
        it 'should return 200' do
          expect_any_instance_of(ActiveRecord::Relation).to receive(:select).with([:id, :name, :ingredient_ct]).and_call_original
          params[:select] = [:id, :name, :ingredient_ct]
          subject
          assert_response 200
        end
      end
    end
  end

  describe '#ingredients' do
    before do
      expect(controller).to receive(:saved_drink).at_least(:once).and_return(drink)
    end
    it 'should return 200' do
      get :ingredients, id: 1, format: :json
      assert_response 200
    end
  end
  
end