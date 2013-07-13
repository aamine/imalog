class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by_email(params[:email])
    if user and user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_url, :notice => "Logged in"
    else  
      flash.now.alert = "Invalid email or password"
      render "new"
    end
  end

  def destroy
    unless logged_in?
      redirect_to root_url, notice: "Not logged in"
      return
    end
    session[:user_id] = nil
    redirect_to root_url
  end
end
