class HomeController < ApplicationController
layout nil

  def home
    if user_signed_in?
      render html: nil, layout: 'application'
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
