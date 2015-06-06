class HomeController < ApplicationController

  def fuzzy_find
    if params[:fuzzy].blank?
      render json:{errors:['Missing search parameter']}, status:406
    else
      hashes = FuzzyFindable.autocomplete(params[:fuzzy])
      render json:hashes
    end
  end

  def sitemap
    @drinks = Drink.select(:id)
    @ingredients = Ingredient.select(:id)
    respond_to do |format|
      format.xml
    end
  end

end
