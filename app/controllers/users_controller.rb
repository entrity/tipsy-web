class UsersController < ApplicationController
  respond_to :json

  def show
    if params[:id]
      if params[:id] =~ /\d+/
        @user = params[:id].to_i == 0 ? current_user : User.find(params[:id])
      else
        @user = User.find_by_nickname(params[:id])
      end
    end
    respond_with @user
  end

end
