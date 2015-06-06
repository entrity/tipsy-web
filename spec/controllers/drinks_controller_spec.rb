describe DrinksController, :type => :controller do

  let(:drink) { build_stubbed :drink, id:1, name:'tom collins', description:'foo', instructions:'bar', ingredients:drink_ingredients }
  let(:drink_ingredients) { build_list :drink_ingredient, 3 }

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
  
end