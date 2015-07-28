class HomeController < ApplicationController
layout nil

  def home
    # Presence of params[:ingredient_id] indicates that this request comes as a consequence
    # of the user selecting an ingredient from the fuzzy finder on the splash screen.
    if user_signed_in? || params[:ingredient_id].present?
      render html: nil, layout: 'application'
    else
      render layout: nil
    end
  end

  def fuzzy_find
    if params[:fuzzy].blank?
      render json:{errors:['Missing search parameter']}, status:406
    else
      opts = {profane:parse_bool(:profane), drinks:parse_bool(:drinks)}
      hashes = FuzzyFindable.autocomplete(params[:fuzzy], opts)
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

  private

    def parse_bool symbol
      if params[symbol].is_a?(String)
        if params[symbol] =~ /1|true|t/i
          true
        elsif params[symbol] =~ /0|false|f/i
          false
        end
      elsif params[symbol] == true
        true
      elsif params[symbol] == false
        false
      end
    end

end
