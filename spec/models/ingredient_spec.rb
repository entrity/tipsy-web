require 'shared_examples/fuzzy_findable.rb'
require 'shared_examples/flaggable.rb'

describe Ingredient do

  let(:flaggable){ build_stubbed :ingredient, revision:revision }
  let(:revision){ build_stubbed :revision }

  include_examples 'fuzzy findable'
  include_examples 'flaggable'

end
