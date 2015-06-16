class HomeController < ApplicationController

  def home
    if user_signed_in?
      return render 'logged_in_home'
    else
      render layout: nil
    end
  end

  def fuzzy_find
    if params[:fuzzy].blank?
      render json:{errors:['Missing search parameter']}, status:406
    else
      hashes = FuzzyFindable.autocomplete(params[:fuzzy], params[:profane])
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
