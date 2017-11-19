require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  
  def setup
    ActionMailer::Base.deliveries.clear
  end
  
  test "invalid submit doesn't create a user" do
    get signup_path
    
    assert_select 'form[action="/signup"]'
    
    assert_no_difference 'User.count' do
      post signup_path, params: { user: { name: "", email: "user@valid",
              password: "foo", password_confirmation: "foo"} }
    end
    
    assert_template 'users/new'
    
    assert_select 'div#error_explanation'
    assert_select 'div.alert'

  end
  
  test "valid submit with activation creates a user" do
    get signup_path
    
    assert_difference 'User.count', 1 do
      post signup_path, params: { user: { name: "Test user", 
            email: "valid@example.com", password: "foobar", 
            password_confirmation: "foobar"} }
    end
    
    # make sure we have an activation email to send
    assert_equal 1, ActionMailer::Base.deliveries.size
    
    # grab the user we created
    user = assigns(:user)
    
    # make sure we're not activated yet
    assert_not user.activated?
    
    # make sure we can't log in because we're not activated
    th_log_in_as user
    assert_not th_logged_in?
    
    # make sure an invalid token doesn't work
    get edit_account_activation_path("invalid token", email: user.email)
    assert_not th_logged_in?
    
    # make sure an invalid email doesn't work
    get edit_account_activation_path(user.activation_token, email: "invalid")
    assert_not th_logged_in?
    
    # try valid token and email and make sure we got activated
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?

    # make sure we're logged in, at the user page, and we got notification
    follow_redirect!
    assert_template 'users/show'
    assert_select 'div.alert'
    assert_not flash.empty?
    assert th_logged_in?
  end
  
end
