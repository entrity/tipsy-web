shared_examples "fuzzy findable" do

  describe '::fuzzy_find' do
    it 'raises no exception' do
     expect{ described_class.fuzzy_find("str") }.to_not raise_exception
    end
  end

end
