class AdminController < ApplicationController
  before_action :require_signed_in
  before_action :require_user_can_admin
  before_action -> { params[:scope] ||= {} }
  PER_PAGE = 30

  def comments
    index Comment
  end

  def ingredient_revisions
    index IngredientRevision
  end

  def photos
    index Photo
  end

  def publish
    @resource = params[:klass].constantize.find(params[:id])
    if params[:status] && @resource.status == params[:status].to_i
      Review.where(open:true, reviewable:@resource).update_all open:false
      case @resource.status
      when Flaggable::REJECTED, Flaggable::NEEDS_REVIEW
        @resource.publish!
      when Flaggable::APPROVED;
        @resource.unpublish!
        @resource.update_attributes status:Flaggable::REJECTED
      end
    end
    redirect_to request.referrer
  end

  def reviews
    params[:scope][:open] = true unless params[:scope].has_key?('open')
    @reviews = paginated_resource Review.where(params[:scope])
    respond_with @reviews
  end

  def revisions
    index Revision
  end

  private

    def paginated_resource scope
      scope.paginate page:params[:page], per_page:PER_PAGE
    end

    def index resource_klass
      @resources = paginated_resource resource_klass.where(params[:scope])
      render 'index'
    end

    def require_user_can_admin
      unless current_user.can_admin?
        if request.format.html?
          flash[:alert] = msg || 'You must have admin privilege take that action'
          redirect_to :root
        else
          render status: 401, text: 'Admin privilege required'
        end
      end
    end

end
