shared_examples "flaggable" do

  describe '#flag!' do
    let(:user){ build_stubbed :user }
    it 'raises no exception' do
      expect(TipsyException::UpdateException).to receive(:assert_update_count).at_least(:once)
      expect{ flaggable.flag!(user) }.to_not raise_exception
    end
  end

end
