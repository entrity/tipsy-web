class DrinksController < ApplicationController
  MAX_RESULTS = 50

  def index
    @drinks = Drink.limit(MAX_RESULTS)
    @drinks = @drinks.where("name LIKE '%#{params[:q]}%'") if params[:q].present?
    respond_with @drinks
  end

  def show
    @drink = Drink.find params[:id]
    @ingredients = @drink.ingredients
      .order('random()')
      .limit(MAX_RESULTS)
  end

end
