class FavouritesController < ApplicationController
  before_action :require_signed_in

  def index
    @favourites = Favourite.where(user:current_user, collection_id:params[:collection_id]).includes(:photo, :drink)
    respond_with @favourites.as_json(only:[:id, :drink_id], methods:[:preview_url, :name])
  end

  def create
    @favourite = Favourite.new model_params
    @favourite.user = current_user
    @favourite.save
    respond_with @favourite
  end

  def update
    if find_collection
      @favourite.update_attributes model_params
      respond_with @favourite
    end
  end

  def destroy
    if find_collection
      @favourite.destroy
      respond_with @favourite
    end
  end

  private

    def find_collection
      @favourite = Favourite.find(params[:id])
      if @favourite.user_id == current_user.id
        @favourite
      else
        render status:401, json:{'error' => 'You are not the owner of the given collection'}
        nil
      end
    end

    def model_params
      params.permit [:drink_id, :collection_id]
    end
end
