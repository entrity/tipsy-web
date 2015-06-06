class DrinksController < ApplicationController
  respond_to :json, :html
  MAX_RESULTS = 50

  def index
    @drinks = Drink.default_scoped
    @drinks = @drinks.fuzzy_find(params[:fuzzy]) if params[:fuzzy].present?
    @drinks = @drinks.for_ingredients(params[:ingredient_id]) if params[:ingredient_id].present?
    @drinks = @drinks.select(params[:select]) if params[:select].present?
    @drinks = @drinks.paginate page:params[:page], per_page:MAX_RESULTS
    set_pagination_headers @drinks
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
    @ingredients = saved_drink.ingredients
    respond_with @ingredients.as_json(methods:[:name])
  end

private

  def saved_drink
    @drink ||= Drink.find params[:id]
  end

end
