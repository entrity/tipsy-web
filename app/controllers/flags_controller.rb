class FlagsController < ApplicationController
  respond_to :json

  def create
    @flag = Flag.new flag_params.merge(user:current_user)
    results_hash = @flag.flaggable && @flag.flaggable.flag!(current_user, 0, @flag.description)
    if results_hash && results_hash['flag_created']
      render nothing:true, status:201
    elsif @flag.valid?
      raise "Flag appears to be valid but did not save in flags#create: #{@flag.inspect}"
    elsif @flag.errors[:user].try(:include?, 'has already been taken')
      render json:{errors:@flag.errors}, status:409
    else
      render json:{errors:@flag.errors}, status:422
    end
  end

  private

    def flag_params
      params.permit(:flaggable_id, :flaggable_type, :description)
    end
end
