FactoryGirl.define do
  factory :drink_ingredient do
    qty "30cc"
    ingredient { build_stubbed :ingredient }
  end
end
