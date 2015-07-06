class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :set_xsrf_token_cookie
  before_action :require_ssl_if_signed_in

  respond_to :json, :html

  def flag
    @record = controller_path.classify.find(params[:id])
    if @record.flag!(current_user)
      render nothing:true, status:200
    else
      respond_with @record
    end
  end

private

  # Redirect to previous page after sign in
  def after_sign_in_path_for(resource)
    sign_in_url = new_user_session_url
    if request.referer == sign_in_url
      super
    else
      stored_location_for(resource) || request.referer || root_path
    end
  end

  def referrer_host_match?
    request.referrer.nil? || URI::parse(request.referrer).host == request.host
  end

  def require_ssl_if_signed_in
    if user_signed_in? && !request.ssl? && Rails.env.production?
      flash[:error] = 'You must use an encrypted connection'
      redirect_to root_url(protocol: :https)
    end
  end

  def set_pagination_headers paginated_array
    response.headers['Tipsy-page'] = paginated_array.current_page.to_i.to_s
    response.headers['Tipsy-total_pages'] = paginated_array.total_pages.to_s
    response.headers['Tipsy-count'] = paginated_array.total_entries.to_s
  end

  def set_xsrf_token_cookie
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def verified_request?
    super || (valid_authenticity_token?(session, cookies['XSRF-TOKEN']) && referrer_host_match?)
  end


end
