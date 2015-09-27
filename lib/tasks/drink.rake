namespace :drink do
  task :count_comments => :environment do
    Drink.find_each do |drink|
      comment_ct = Comment.where(drink_id:drink.id).count
      drink.update_attributes! comment_ct: comment_ct
    end
  end

  task :count_votes => :environment do
    Drink.find_each do |drink|
      up_vote_ct = Vote.where(votable:drink, sign:1).count
      dn_vote_ct = Vote.where(votable:drink, sign:-1).count
      drink.update_attributes! up_vote_ct: up_vote_ct, dn_vote_ct: dn_vote_ct
    end
  end

  task :set_related => :environment do
    start_time = Time.now
    File.write('tmp/set-related.log', '')
    ActiveRecord::Base.connection.uncached do
      Drink.find_each do |drink|
        ingredient_ids = drink.ingredients.pluck(:ingredient_id)
        candidates = Drink
          .joins(:ingredients)
          .where('id != ?', drink.id)
          .where('drinks_ingredients.ingredient_id' => ingredient_ids)
          .includes(:ingredients)
          .distinct
        candidates.to_a.sort! do |a, b|
          if common_ingredients(drink, a) == common_ingredients(drink, b)
            ingredient_ct_diff(drink, a) <=> ingredient_ct_diff(drink, b)
          else
            common_ingredients(drink, a) <=> common_ingredients(drink, b)
          end
        end
        related_drinks = candidates[0...5]
        drink.update_attributes! related_drink_ids:related_drinks.map(&:id)
        # Debug info
        puts drink.id
        if drink.id % 20 == 0
          GC.start
          File.open('tmp/set-related.log', 'a') {|f| f.write File.read("/proc/#{Process.pid}/statm") } if File.exist?("/proc/#{Process.pid}/statm")
          puts "%05d seconds elapsed" % (Time.now - start_time)
        end
      end
    end
  end

  def common_ingredients drink, other
    attr_name = "@drink_#{drink.id}_common_ingredients"
    other.instance_variable_get(attr_name) || begin
      count = (drink.ingredients.map(&:ingredient_id) & other.ingredients.map(&:ingredient_id)).length
      other.instance_variable_set attr_name, count
    end
  end

  def ingredient_ct_diff drink, other
    attr_name = "@drink_#{drink.id}_distinct_ingredients"
    other.instance_variable_get(attr_name) || begin
      count = (drink.ingredients.length - other.ingredients.length).abs
      other.instance_variable_set attr_name, count
    end
  end
end
