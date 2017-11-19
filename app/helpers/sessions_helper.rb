module SessionsHelper
  
  def log_in(user)
    session[:user_id] = user.id
  end
  
  def remember(user)
    
    # Call user.remember to have the user create a remember_token.
    user.remember
    
    # In cookies, stash the encrypted userid and the remember_token.
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end
  
  def current_user?(user)
    user == current_user
  end
  
  def current_user
    
    # Do we have a user_id in our session?
    if(user_id = session[:user_id])
      
      # Just use that.
      @current_user ||= User.find_by(id: user_id)
      
    # Otherwise, do we have an encrypted user_id in our cookies?
    elsif(user_id = cookies.signed[:user_id])
      
      # Find the user.
      user = User.find_by(id: user_id)
      
      # Does the remember_token authenticate them?
      if user && user.authenticated?(:remember, cookies[:remember_token])
        
        # Log in and use this user.
        log_in user
        @current_user = user
      end
    end
  end

  def logged_in?
    !current_user.nil?
  end
  
  def forget(user)
    # Clear out the user remember data.
    user.forget
    # Clear our auth cookies.
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end
  
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end
  
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end
  
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
  
end
