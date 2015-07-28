shared_examples "flaggable" do

  describe '#flags' do
    it 'returns a relation' do
      expect(flaggable.flags).to be_a ActiveRecord::Relation
    end
  end

  describe '#flag!' do
    let(:user){ build_stubbed :user }
    let(:bits){ Flag::INDECENT }
    let(:log_points){Flaggable::FLAG_PTS_LIMIT}
    subject{flaggable.flag!(user, bits, 'description')}

    it 'raises no exception' do
      expect{ subject }.to_not raise_exception
    end
    it 'has default status' do
      subject
      expect(flaggable.status).to eq(default_status)
    end
    it 'returns true when flag is created, false when flag already exists' do
      ret = flaggable.flag!(user, bits, 'description')
      expect(ret['flag_created']).to eq('t')
      ret = flaggable.flag!(user, bits, 'description')
      expect(ret['flag_created']).to eq(nil)
    end
    it 'creates a flag the first time, not the second' do
      expect{subject}.to change(Flag, :count).by(1)
      expect{subject}.to change(Flag, :count).by(0)
    end

    context 'when flags exceed limit' do
      before do
        expect(user).to receive(:log_points).and_return(log_points)
      end

      it 'unpublishes self or revision' do
        subject
        expect(flaggable.status).to eq(Flaggable::NEEDS_REVIEW)
      end

    end

  end

end
