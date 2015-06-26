shared_examples "flaggable" do

  describe '#flags' do
    it 'returns a relation' do
      expect(flaggable.flags).to be_a ActiveRecord::Relation
    end
  end

  describe '#flag!' do
    let(:user){ build_stubbed :user }
    let(:bits){ HasFlagBits::INDECENT }
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

      context 'when there are two Flags with flag_bits' do
        let(:user_2){ build_stubbed :user }
        let(:log_points){Flaggable::FLAG_PTS_LIMIT - 1}
        let(:flag_a){build_stubbed :flag, flag_bits:HasFlagBits::COPYRIGHT}
        subject{
          flaggable.flag!(user, flag_a.flag_bits)
          flaggable.flag!(user_2, flag_b.flag_bits)
        }
        before do
          expect(user_2).to receive(:log_points).and_return(log_points)
        end
        context 'of values INDECENT & COPYRIGHT' do
          let(:flag_b){build_stubbed :flag, flag_bits:HasFlagBits::INDECENT}
          it 'the Review created has both flags' do
            subject
            review = flaggable.review
            expect(review.indecent_flag?).to be true
            expect(review.copyright_flag?).to be true
            expect(review.spam_flag?).to be false
          end
        end
        context 'with both values bein COPYRIGHT' do
          let(:flag_b){build_stubbed :flag, flag_bits:HasFlagBits::COPYRIGHT}
          it 'the Review created has both flags' do
            subject
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
