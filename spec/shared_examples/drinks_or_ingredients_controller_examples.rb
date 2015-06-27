shared_examples "drinks or ingredients controller" do

  describe '#index' do
    subject{ get :index, params }
    context 'with json format' do
      let(:params){{format: :json}}
      it 'should return 200' do
        subject
        assert_response 200
      end
      context 'with select[] param' do
        it 'should return 200' do
          expect_any_instance_of(ActiveRecord::Relation).to receive(:select).with([:id, :name]).and_call_original
          params[:select] = [:id, :name]
          subject
          assert_response 200
        end
      end
      context 'with fuzzy param' do
        it 'should return 200' do
          params[:fuzzy] = "spr"
          subject
          assert_response 200
        end
      end
      context 'with page param' do
        it 'should return 200' do
          expect_any_instance_of(ActiveRecord::Relation).to receive(:paginate).with({page:3, per_page:DrinksController::MAX_RESULTS}).and_call_original
          params[:page] = 3
          subject
          assert_response 200
        end
      end
    end
  end

end
