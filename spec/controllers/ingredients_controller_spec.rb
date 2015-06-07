require 'shared_examples/drinks_or_ingredients_controller.rb'

describe IngredientsController, :type => :controller do

  include_examples 'drinks or ingredients controller'

  describe '#index' do
    subject{ get :index, params }
    context 'with json format' do
      let(:params){{format: :json}}
    end
  end

end
