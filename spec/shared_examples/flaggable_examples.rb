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
    subject{flaggable.flag!(user, bits)}

    it 'raises no exception' do
      expect{ subject }.to_not raise_exception
    end
    it 'has default status' do
      subject
      expect(flaggable.status).to eq(default_status)
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
