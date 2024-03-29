class DrinksController < ApplicationController
  respond_to :json, :html
  MAX_RESULTS = 50
  MIN_INGREDIENT_CT_FOR_SUGGESTIONS = 1

  before_action :require_signed_in, only: [:new, :edit, :update, :create, :destroy]

  def index
    move_ingredient_id_params_to_canonical_ids
    @drinks = Drink.default_scoped
    @drinks = @drinks.where(id:params[:id]) if params[:id].present?
    if params[:fuzzy].present?
      @drinks = @drinks.fuzzy_find(params[:fuzzy])
    elsif request.format.html?
      @drinks = @drinks.order(:name)
    end
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
    if params[:with_photo]
      @drinks.includes(:photo)
      @drinks = @drinks.map do |drink|
        hash = drink.as_json
        hash['photo_url'] = drink.photo.file.url(:medium) if drink.photo.present?
        hash
      end
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
          comment_ids = @comments.map(&:id)
          photo_ids   = @photos.map(&:id)
          # Fetch flags created by this user for any photos or comments that pertain to `saved_drink`
          @user_flags  = Flag.for_user_photos_comments(current_user.id, photo_ids, comment_ids)
          @user_votes  = Vote.for_user_photos_comments_drink(current_user.id, photo_ids, comment_ids, saved_drink.id)
          @user_tips   = CommentTipVote.where(user_id:current_user.id, comment_id:comment_ids)
          @user_fav_id = Favourite.where(drink:saved_drink, user:current_user).pluck(:id).first
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
    if params[:canonical_ingredient_id].is_a?(Array) && params[:canonical_ingredient_id].length >= MIN_INGREDIENT_CT_FOR_SUGGESTIONS
      suggestion_set = DrinkSuggestionSet.new(params[:canonical_ingredient_id])
      @suggestions = suggestion_set.output
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
