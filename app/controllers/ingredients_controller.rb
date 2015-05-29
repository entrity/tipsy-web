class IngredientsController < ApplicationController
  MAX_RESULTS = 50

  def index
    @ingredients = Ingredient.limit(MAX_RESULTS)
    @ingredients = @ingredients.where("name LIKE '%#{params[:q]}%'") if params[:q].present?
    respond_with @ingredients
  end

  def show
    @ingredient = Ingredient.find params[:id]
    @drinks = @ingredient.drinks
      .order('random()')
      .limit(MAX_RESULTS)
  end

end
