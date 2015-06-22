shared_examples "flaggable" do

  describe '#flag!' do
    let(:user){ build_stubbed :user }
    before do
      if flaggable.is_a?(Revisable)
        revision_user = build_stubbed :user
        flaggable.create_revision text:'this text', user:revision_user, flaggable:flaggable
      end
    end
    it 'raises no exception' do
      expect{ flaggable.flag!(user) }.to_not raise_exception
    end
    it 'has default status' do
      flaggable.flag!(user)
      expect(unpublishable.status).to eq(default_status)
    end

    context 'when flags exceed limit' do
      it 'unpublishes self or revision' do
        @unpublishable = unpublishable
        expect(user).to receive(:log_points).and_return(Flaggable::FLAG_PTS_LIMIT)
        flaggable.flag!(user)
        expect(@unpublishable.status).to eq(Flaggable::NEEDS_REVIEW)
      end
    end
  end

  def unpublishable
    flaggable.is_a?(Revisable) ? flaggable.revision : flaggable
  end

end
