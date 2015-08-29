class FavouritesCollectionsController < ApplicationController
  before_action :require_signed_in

  def index
    @collections = FavouritesCollection.where(user:current_user)
    respond_with @collections
  end

  def create
    @collection = FavouritesCollection.new model_params
    @collection.user = current_user
    @collection.save
    respond_with @collection
  end

  def update
    if find_collection
      @collection.update_attributes model_params
      respond_with @collection
    end
  end

  def destroy
    if find_collection
      @collection.destroy
      respond_with @collection
    end
  end

  private

    def find_collection
      @collection = FavouritesCollection.find(params[:id])
      if @collection.user_id == current_user.id
        @collection
      else
        render status:401, json:{'error' => 'You are not the owner of the given collection'}
        nil
      end
    end

    def model_params
      params.permit [:name, :preview_drink_id, :preview_url]
    end
end
