class UsersController < ApplicationController
  respond_to :json

  before_action :require_signed_in, only: :unviewed_point_distributions

  def show
    get_user
    if request.format.html?
      @canonical_url = 'http://tipsyology.com' + @user.url_path
    end
    respond_with @user
  end

  def trophies
    @trophies = get_user.trophies
  end

  # GET
  def unviewed_point_distributions
    @point_distributions = PointDistribution.where(user_id: current_user.id, viewed: false)
    respond_with @point_distributions.as_json
  end

  # PUT
  def viewed_point_distributions
    @updates = PointDistribution.where(user_id: current_user.id, id:params[:id]).update_all(viewed: true)
    respond_with @updates
  end

  private

    def get_user
      @user ||= (
      if params[:id]
        if params[:id] =~ /\d+/ || params[:id].is_a?(Fixnum)
          @user = params[:id].to_i == 0 ? current_user : User.find(params[:id])
        else
          @user = User.where('nickname ilike ?', params[:id]).first
        end
      end)
    end

end
