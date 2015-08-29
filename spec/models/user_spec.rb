require 'rails_helper.rb'

describe User do
  let(:user){create :user, comment_ct:19}

  describe 'increment_comment_ct!' do
    context 'when comment_ct is 19' do
      it 'increments to 20 and creates a trophy and updates trophy count' do
        expect(user.trophies.count).to eq 0
        expect{user.increment_comment_ct!}.to change{user.bronze_trophy_ct}.by(1)
        expect(user.comment_ct).to eq 20
        expect(user.reload.comment_ct).to eq 20
        expect(user.trophies.count).to eq 1
      end
    end
  end

  describe 'save' do
    context 'when no_profanity gets set' do
      it 'creates a NO_PROFANITY trophy' do
        expect(user.trophies.where(category_id:TrophyCategory::NO_PROFANITY.id).count).to eq 0
        user.update_attributes no_profanity:true
        expect(user.trophies.where(category_id:TrophyCategory::NO_PROFANITY.id).count).to eq 1
      end
    end
  end

end
