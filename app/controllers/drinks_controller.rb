class DrinksController < ApplicationController
  respond_to :json, :html
  MAX_RESULTS = 50

  def index
    @drinks = Drink.limit(MAX_RESULTS)
    @drinks = @drinks.where("name LIKE '%#{params[:q]}%'") if params[:q].present?
    @drinks = @drinks.offset(params[:offset]) if params[:offset].present?
    if params[:ingredient_id].present?
      # Scope results to Drinks which include all of the indicated ingredients
      @drinks = @drinks.join(:ingredients)
        .where('drinks_ingredients.ingredient_id IN ?', params[:ingredient_id])
        .distinct
        .order('ingredient_ct')
    end
    if params[:select].present?
      @drinks = @drinks.select(params[:select])
    elsif request.format.json?
      @drinks = @drinks.select([:id, :name, :ingredient_ct])
    end
    respond_with @drinks
  end

  def show
    respond_to do |format|
      format.html {
        @ingredients = saved_drink.ingredients
          .order('random()')
          .limit(MAX_RESULTS)
      }
      format.json {
        respond_with saved_drink
      }
    end
  end

  def ingredients
  end

  def ingredient_ids
  end

  private

  def saved_drink
    @drink ||= Drink.find params[:id]
  end

end
