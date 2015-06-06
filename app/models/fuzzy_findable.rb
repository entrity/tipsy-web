module FuzzyFindable

  def self.included(base)
    base.class_eval do
      scope :fuzzy_find, -> term {
        pattern = '%' + term.chars.join("%") + '%'
        where("#{base.table_name}.name LIKE ?", pattern)
      }
    end
  end

  def fdsa
  end

end