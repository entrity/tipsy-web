require 'shared_examples/fuzzy_findable.rb'
require 'shared_examples/flaggable.rb'

describe Drink do

  let(:flaggable){ build_stubbed :drink, revision:revision }
  let(:revision){ build_stubbed :revision }

  include_examples 'fuzzy findable'
  include_examples 'flaggable'

end
