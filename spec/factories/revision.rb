FactoryGirl.define do
  factory :revision do
    description "and this way she won't have to run away"
    instructions "and she can keep her regrets at bay"
    name "every day"
    ingredients [{qty:'5tsp', ingredient_id:123}, {qty:'3pt', ingredient_id:234}]
    prep_time '10 min'
    calories 356
  end
end
