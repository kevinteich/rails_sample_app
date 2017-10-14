require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  
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
  
  test "valid submit creates a user" do
    get signup_path
    
    assert_difference 'User.count', 1 do
      post signup_path, params: { user: { name: "Test user", 
            email: "valid@example.com", password: "foobar", 
            password_confirmation: "foobar"} }
    end
    
    follow_redirect!
    
    assert_template 'users/show'
    
    assert_select 'div.alert'
  
    assert_not flash.empty?
    
    assert th_logged_in?
  end
  
end
