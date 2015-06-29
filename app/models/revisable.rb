module Revisable

  def self.included(base)
    base.belongs_to :revision, dependent: :destroy, inverse_of: :revisable
    base.has_many :revisions, dependent: :destroy, inverse_of: :revisable, as: :revisable
  end

  def flag!
    revision.try(:flag!)
  end

end
