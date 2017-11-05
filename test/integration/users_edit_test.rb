require 'test_helper'

class UsersEditTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end
  
  test "edit with invalid information" do
    th_log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), params: { user: { name: "", email: "foo@invalid",
                                    password: "foo",
                                    password_confirmation: "bar" } }
    assert_template 'users/edit'
    assert_select "div.alert", "The form contains 4 errors."
  end
  
  test "successful edit with friendly forwarding" do
    get edit_user_path(@user)
    th_log_in_as(@user)
    assert_redirected_to edit_user_path(@user)
    assert_nil session[:forwarding_url]
    patch user_path(@user), params: { user: { name: "Update", 
                                    email: "example2@example.com",
                                    password: "",
                                    password_confirmation: "" } }
    assert_not flash.empty?
    assert_redirected_to @user

    @user.reload
    assert_equal "Update", @user.name
    assert_equal "example2@example.com", @user.email
  end

end
