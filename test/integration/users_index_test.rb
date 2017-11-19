require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    @unactivated = users(:unactivated)
    @admin = users(:michael)
    @non_admin = users(:archer)
  end
  
  test "index including pagination" do
    th_log_in_as(@user)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination'
    
    # Make sure we have all the users from page 1...
    User.paginate(page: 1).each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
      assert user.activated?
    end
    
    # ...and none from page 2.
    User.paginate(page: 2).each do |user|
      assert_select 'a[href=?]', user_path(user), count: 0
    end
  end

  test "index as admin including pagination and delete links" do
    th_log_in_as(@admin)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination'
    
    User.paginate(page: 1).each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
      unless user == @admin 
        assert_select 'a[href=?]', user_path(user), text: 'delete'
      end
    end

    assert_difference 'User.count', -1 do
      delete user_path(@non_admin)
    end
  end
  
  test "index as non-admin" do
    th_log_in_as(@non_admin)
    get users_path
    assert_select 'a', text: 'delete', count: 0
  end

  test "view unactiated user redirects to root" do
    th_log_in_as(@user)
    get user_path(@unactivated)
    assert_redirected_to root_url
  end
end
