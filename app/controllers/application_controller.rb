class ApplicationController < ActionController::Base
  def require_authorize
    redirect_to new_session_url unless logged_in?
  end
  private :require_authorize

  before_action :set_blog
  def set_blog
    @blog = Blog.instance
  end
  private :set_blog

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  def logged_in?
    session[:user_id] ? true : false
  end

  helper_method :logged_in?

  def current_user
    return nil unless logged_in?
    @current_user ||= User.find(session[:user_id])
  end

  helper_method :current_user
end
