describe FuzzyFindable do

  describe '::autocomplete' do
    it 'raises no exception' do
      expect{ FuzzyFindable.autocomplete('str').to_not raise_exception }
    end
    context 'with profane = false' do
      it 'raises no exception' do
        expect{ FuzzyFindable.autocomplete('str').to_not raise_exception }
      end
    end
    context 'with profane = true' do
      it 'raises no exception' do
        expect{ FuzzyFindable.autocomplete('str').to_not raise_exception }
      end
    end
  end
end
