class FlagsController < ApplicationController
  respond_to :json

  def create
    @flag = Flag.new flag_params
    @flag.user = current_user
    if @flag.save
      @flag.flaggable.increment_flag_points!(@flag.points)
    end
    respond_with @flag
  end

  private

    def flag_params
      params.require(:flaggable_id, :flaggable_type)
    end
end
