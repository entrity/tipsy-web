require 'shared_examples/fuzzy_findable_examples.rb'
require 'shared_examples/flaggable_examples.rb'

describe Drink do

  let(:flaggable){ Drink.create }
  let(:default_status){Flaggable::NEEDS_REVIEW}

  include_examples 'fuzzy findable'
  include_examples 'flaggable'

end
