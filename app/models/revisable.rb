module Revisable

  def self.included(base)
    unless base.attribute_method?(:text)
      raise "No text column on class #{base.name}"
    end
    base.belongs_to :revision, dependent: :destroy, inverse_of: :revisable
    base.has_many :revisions, dependent: :destroy, inverse_of: :revisable, as: :revisable
  end

  def flag!
    revision.try(:flag!)
  end

end
