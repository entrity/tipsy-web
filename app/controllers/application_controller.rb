class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

private

  def set_pagination_headers paginated_array
    response.headers['Tipsy-page'] = paginated_array.current_page
    response.headers['Tipsy-total_pages'] = paginated_array.total_pages
  end

end
