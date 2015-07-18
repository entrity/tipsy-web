class PhotosController < ApplicationController
  respond_to :json

  before_action :require_signed_in

  def create
    @photo = Photo.new photo_params
    @photo.user = current_user
    @photo.save
    respond_with @photo
  end

  private

    def photo_params
      permitted_params = params.permit(:drink_id, :file)
      if params[:data].is_a? String
        hash = JSON.parse(params[:data])
        ['drink_id', 'alt'].each do |key|
          permitted_params[key] ||= hash[key] if hash.has_key?(key)
        end
      end
      permitted_params
    end

    def photo_url photo
      photo.file.url
    end

end
