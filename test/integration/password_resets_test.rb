require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end
  
  test "password resets" do
    
    # go to the "forgot password" page
    get new_password_reset_path
    assert_template 'password_resets/new'

    # try an invalid email and check for error message, same page
    post password_resets_path, params: {password_reset: {email: "" }}
    assert_not flash.empty?
    assert_template 'password_resets/new'
    
    # try a valid email and make sure that a new reset digest was created
    # and that the reset mail got sent, and we were set to the home page
    post password_resets_path, params: {password_reset: {email: @user.email }}
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    
    # check that all the incorrect ways to get to the reset form take
    # us back to the home page
    user = assigns(:user)
    
    # right token, wrong email.
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    
    # valid token and email, inactive user
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    user.toggle!(:activated)
    
    # wrong token, right email.
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    
    # now check the correct token and email and make sure we see the form.
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    
    # check some invalid form entries. confirm doesn't match:
    patch password_reset_path(user.reset_token),
      params: { email: user.email, 
                user: { password: "doesnt", password_confirmation: "match" }}
    assert_select 'div#error_explanation'
    
    # check empty password.
    patch password_reset_path(user.reset_token),
      params: { email: user.email, 
                user: { password: "", password_confirmation: "" }}
    assert_select 'div#error_explanation'

    # check valid password and confirmation.
    patch password_reset_path(user.reset_token),
      params: { email: user.email, 
                user: { password: "foobar", password_confirmation: "foobar" }}
    assert th_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
    
    # make sure the digest was cleared
    assert_nil user.reload.reset_digest
  end
  
  test "expired token" do
    
    # make a valid password reset request
    get new_password_reset_path
    post password_resets_path, params: {password_reset: {email: @user.email }}

    # set the set at time to be 3 hours ago
    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)

    # request the reset page with the correct email and token
    get edit_password_reset_path(@user.reset_token, email: @user.email)
    
    # make sure we get redirected to the form again, with the "expired" flash
    assert_redirected_to new_password_reset_path
    assert_match(/expired/i, flash[:danger])
  end

end
