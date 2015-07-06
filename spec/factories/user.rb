FactoryGirl.define do
  factory :user do
    name { generate :name }
    email { generate :email }
    password 'password'
    password_confirmation 'password'
  end
end

# Defines a new sequence
FactoryGirl.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end
end

# Defines a new sequence
FactoryGirl.define do
  sequence :name do |n|
    "name#{n}"
  end
end
