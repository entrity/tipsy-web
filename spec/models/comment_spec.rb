require 'shared_examples/flaggable.rb'

describe Drink do

  let(:flaggable){ build_stubbed :comment, user:user }
  let(:user){ build_stubbed :user}

  include_examples 'flaggable'

end
