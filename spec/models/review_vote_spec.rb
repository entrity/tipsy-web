require 'rails_helper.rb'

describe ReviewVote do

  describe 'create' do
    subject{ ReviewVote.create(review:review, user:user, points:points) }
    let(:review){ Review.create reviewable:revision, points: 2, contributor: contributor }
    let(:revision){ build_stubbed :revision }
    let(:points){ 1 }
    let(:user){ create :user, points:4 }
    let(:contributor){ build_stubbed :user }
    context 'when the contributed points do NOT push the Review past its closure threshold' do
      it 'does NOT close the Review' do
        subject
        expect(review.open).to eq(true)
      end
      it 'does NOT award points to the voter' do
        subject
        expect(user.points).to eq(4)
      end
      context 'when points = 1' do
        it 'changes the points of the Review by 1' do
          subject
          expect(review.points).to eq(3)
        end
      end
      context 'when points = -2' do
        let(:points){-2}
        it 'changes the points of the Review by -2' do
          subject
          expect(review.points).to eq(0)
        end
      end
    end
    context 'when the contributed points DO push the Review past its closure threshold' do
      let(:points){ Review::POINTS_TO_CLOSE }
      before do
        allow(revision).to receive(:publish!)
        allow(review).to receive(:reviewable).and_return(revision)
      end
      it 'executes without error' do
        expect{subject}.to_not raise_exception
      end
      context 'when vote brings winning votes to 10' do
        let(:user){ create :user, points:4, majority_review_votes:9}
        it 'creates a WINNING_VOTES_10 trophy' do
          expect(user.trophies.where(category_id:TrophyCategory::WINNING_VOTES_10.id).count).to eq 0
          subject
          expect(user.trophies.where(category_id:TrophyCategory::WINNING_VOTES_10.id).count).to eq 1
        end
      end
    end
  end

end
