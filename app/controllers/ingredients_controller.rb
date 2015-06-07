class IngredientsController < ApplicationController
  respond_to :json, :html
  MAX_RESULTS = 50

  def index
    @ingredients = Ingredient.default_scoped
    @ingredients = @ingredients.fuzzy_find(params[:fuzzy]) if params[:fuzzy].present?
    @ingredients = @ingredients.for_drink(params[:drink_id]) if params[:drink_id].present?
    @ingredients = @ingredients.select(params[:select]) if params[:select].present?
    @ingredients = @ingredients.paginate page:params[:page], per_page:MAX_RESULTS
    set_pagination_headers @ingredients
    respond_with @ingredients
  end

  def show
    @ingredient = Ingredient.find params[:id]
    @drinks = @ingredient.drinks
      .order('random()')
      .limit(MAX_RESULTS)
  end

end
