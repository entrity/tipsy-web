describe ReviewsController, :type => :controller do

  describe '#count' do
    subject{ get :count }
    context 'without login' do
      it 'redirects' do
        expect(subject).to redirect_to '/users/sign_in'
      end
    end
    # context 'with json format' do
    #   let(:params){{format: :json}}
    # end
  end

end
