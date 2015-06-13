class UsersController < ApplicationController
  respond_to :json

  def show
    @user = params[:id].to_i == 0 ? current_user : User.find(params[:id])
    respond_with @user
  end

end
