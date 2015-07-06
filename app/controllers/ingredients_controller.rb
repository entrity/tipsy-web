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

  def names
    if params[:id].blank?
      respond_with Hash.new
    else
      sql = Ingredient.where(id:params[:id]).select([:id,:name]).to_sql
      res = Ingredient.connection.execute(sql)
      map = Hash[res.map{|x| [x['id'], x['name']] }]
      respond_with map
    end
  end
end
