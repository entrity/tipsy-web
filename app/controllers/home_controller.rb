class HomeController < ApplicationController
layout nil

  def home
    # Presence of params[:ingredient_id] indicates that this request comes as a consequence
    # of the user selecting an ingredient from the fuzzy finder on the splash screen.
    if user_signed_in? || params[:ingredient_id].present? || params[:discover]
      @canonical_url = 'http://tipsyology.com/discover'
      render 'signed_in_home', layout: 'application'
    else
      render layout: nil
    end
  end

  # Render JSON for Drinks to show on signed-in home page
  def drinks
    top_drinks = Drink.top.limit(5)
    exclude_drink_ids = top_drinks.map(&:id)
    top_gin_drinks = Drink.top(Ingredient.gin_canonical_id, exclude_drink_ids).limit(5)
    exclude_drink_ids += top_gin_drinks.map(&:id)
    top_vodka_drinks = Drink.top(Ingredient.vodka_canonical_id, exclude_drink_ids).limit(5)
    exclude_drink_ids += top_vodka_drinks.map(&:id)
    top_margarita_drinks = Drink.top([Ingredient.triple_sec_canonical_id, Ingredient.tequila_canonical_id], exclude_drink_ids).limit(5)
    render json: {
      general:      top_drinks,
      gin_drinks:   top_gin_drinks,
      vodka_drinks: top_vodka_drinks,
      margaritas:   top_margarita_drinks,
    }
  end

  def fuzzy_find
    if params[:fuzzy].blank?
      render json:{errors:['Missing search parameter']}, status:406
    else
      opts = {
        profane:                parse_bool(:profane),
        drinks:                 parse_bool(:drinks),
        exclude_ingredient_ids: params[:exclude_ingredient_ids],
      }
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
