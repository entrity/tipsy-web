shared_examples "flaggable" do

  describe '#flags' do
    it 'returns a relation' do
      expect(flaggable.flags).to be_a ActiveRecord::Relation
    end
  end

  describe '#flag!' do
    let(:user){ build_stubbed :user }

    it 'raises no exception' do
      expect{ flaggable.flag!(user) }.to_not raise_exception
    end
    it 'has default status' do
      flaggable.flag!(user)
      expect(flaggable.status).to eq(default_status)
    end

    context 'when flags exceed limit' do
      before do
        expect(user).to receive(:log_points).and_return(Flaggable::FLAG_PTS_LIMIT)
      end

      it 'unpublishes self or revision' do
        flaggable.flag!(user)
        expect(flaggable.status).to eq(Flaggable::NEEDS_REVIEW)
      end

      context 'when there are two Flags with flag_bits' do
        let(:dummy_relation){Flag.all}
        let(:flag_a){build_stubbed :flag, flag_bits:HasFlagBits::COPYRIGHT}
        before do
          expect(flaggable).to receive(:flags).and_call_original
          expect(flaggable).to receive(:flags).and_return(dummy_relation)
          expect(dummy_relation).to receive(:pluck).with(:flag_bits).and_return([flag_a.flag_bits, flag_b.flag_bits])
        end
        context 'of values INDECENT & COPYRIGHT' do
          let(:flag_b){build_stubbed :flag, flag_bits:HasFlagBits::INDECENT}
          it 'the Review created has both flags' do
            flaggable.flag!(user)
            review = flaggable.review
            expect(review.indecent_flag?).to be true
            expect(review.copyright_flag?).to be true
            expect(review.spam_flag?).to be false
          end
        end
        context 'with both values bein COPYRIGHT' do
          let(:flag_b){build_stubbed :flag, flag_bits:HasFlagBits::COPYRIGHT}
          it 'the Review created has both flags' do
            flaggable.flag!(user)
            review = flaggable.review
            expect(review.indecent_flag?).to be false
            expect(review.copyright_flag?).to be true
            expect(review.spam_flag?).to be false
          end
        end
      end
    end

  end

end
