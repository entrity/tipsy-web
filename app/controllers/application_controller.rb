class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  protect_from_forgery with: :null_session
  before_action :set_xsrf_token_cookie

private

  def set_pagination_headers paginated_array
    response.headers['Tipsy-page'] = paginated_array.current_page.to_i.to_s
    response.headers['Tipsy-total_pages'] = paginated_array.total_pages.to_s
    response.headers['Tipsy-count'] = paginated_array.total_entries.to_s
  end

  def set_xsrf_token_cookie
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def verified_request?
    super || form_authenticity_token == cookies['XSRF-TOKEN']
  end

end
