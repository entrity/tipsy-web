class DrinksController < ApplicationController
  respond_to :json, :html
  MAX_RESULTS = 50

  def index
    move_ingredient_id_params_to_canonical_ids
    @drinks = Drink.default_scoped
    @drinks = @drinks.fuzzy_find(params[:fuzzy]) if params[:fuzzy].present?
    @drinks = @drinks.select(params[:select]) if params[:select].present?
    @drinks = @drinks.where(profane:params[:profane]) if params[:profane].present?
    if params[:canonical_ingredient_id].present?
      @drinks = @drinks.for_exclusive_ingredients(params[:canonical_ingredient_id])
    end
    if params[:no_paginate]
      @drinks = @drinks.limit(MAX_RESULTS)
    else
      @drinks = @drinks.paginate page:params[:page], per_page:MAX_RESULTS
      set_pagination_headers @drinks
    end
    respond_with @drinks
  end

  def show
    respond_to do |format|
      format.html {
        @canonical_url = 'http://tipsyology.com' + saved_drink.url_path
        @meta_photo    = saved_drink.top_photo.try(:url)
        @ingredients   = saved_drink.ingredients
          .includes(:ingredient)
          .order('sort DESC')
          .limit(MAX_RESULTS)
        @photos = saved_drink.photos.where(status:Flaggable::APPROVED).order(:score)
        @comments = saved_drink.comments.order(:score)
        if user_signed_in?
          # Fetch flags created by this user for any photos or comments that pertain to `saved_drink`
          @user_flags = Flag.for_user_photos_comments(current_user.id, @photos.map(&:id), @comments.map(&:id))
          @user_votes = Vote.for_user_photos_comments_drink(current_user.id, @photos.map(&:id), @comments.map(&:id), saved_drink.id)
        end
      }
      format.json {
        respond_with saved_drink
      }
    end
  end

  def edit
    render layout:'application', text:%q(<ng-include src="'/drinks/edit.html'"></ng-include>)
  end
  alias_method :new, :edit

  def suggestions
    move_ingredient_id_params_to_canonical_ids
    if params[:canonical_ingredient_id].is_a?(Array) && params[:canonical_ingredient_id].length >= 3
      @candidates = Drink.suggestions(params[:canonical_ingredient_id]).map{|hash| DrinkSuggestion.new(hash) }
      if @candidates.length > 0
        min_distance = @candidates.first.distance
        diffs = {} # map of diff (Array) to suggestions (Array of DrinkSuggestion)
        max_diff_freq = 0
        max_diff_drinks = nil
        @candidates.each do |s|
          next unless s.distance == min_distance
          s.diff = s.required_canonical_ingredient_ids - params[:canonical_ingredient_id]
          diffs[s.diff] ||= []
          diffs[s.diff] << s
          if max_diff_freq < diffs[s.diff].length
            max_diff_freq = diffs[s.diff].length
            max_diff_drinks = diffs[s.diff]
          end
        end
        if max_diff_drinks
          needed_ingredients = Ingredient.where(id:max_diff_drinks.first.diff)
          @suggestions = {drinks:max_diff_drinks, ingredients:needed_ingredients}
        end
      end
    end
    respond_with @suggestions || []
  end

  def ingredients
    @ingredients = saved_drink.ingredients.order('sort DESC')
    respond_with @ingredients.as_json(methods:[:name])
  end

  # Get published revisions
  def revisions
    @revisions = saved_drink.revisions.where(status:Flaggable::APPROVED)
    respond_with @revisions
  end

private

  def move_ingredient_id_params_to_canonical_ids
    if params[:ingredient_id].present?
      params[:canonical_ingredient_id] ||= []
      params[:canonical_ingredient_id] += Ingredient.where(id:params[:ingredient_id]).pluck(:canonical_id)
    end
  end

  def saved_drink
    @drink ||= Drink.find params[:id]
  end

end
