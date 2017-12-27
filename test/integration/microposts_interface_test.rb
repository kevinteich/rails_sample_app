require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end
  
  test "micropost interface" do
  
    th_log_in_as(@user)
    
    get root_path
    assert_template 'static_pages/home'
    
    assert_select 'div.pagination'
    assert_select 'input[type=file]'

    # Make sure we have all the microposts from page 1, and that they
    # have delete links if they're our posts...
    @user.feed.paginate(page: 1).each do |m|
      assert_select 'li[id=?]', "micropost-" + m.id.to_s
      assert_match m.content, response.body
      assert_select 'a[href=?]', micropost_path(m), text: 'delete',
        count: m.user == @user ? 1 : 0
    end
    
    # ...and none from page 2.
    @user.feed.paginate(page: 2).each do |m|
      assert_select 'li[id=?]', "micropost-" + m.id.to_s, count: 0
      assert_no_match m.content, response.body
    end

    # Make sure posting an empty message doesn't do anything.
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: {content: ""} }
    end
    assert_select 'div#error_explanation'
    
    # Check the count.
    assert_match @user.microposts.count.to_s + " microposts", response.body
    
    # Make sure a valid post works and the post is found in the feed page.
    content = "Hello world"
    picture = fixture_file_upload('test/fixtures/rails.png', 'image/png')
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: { micropost: {content: content, 
                                                  picture: picture} }
    end
    
    assert assigns(:micropost).picture?
    assert_redirected_to root_url
    follow_redirect!
    
    assert_match content, response.body
    
    # Check the count after the delete.
    assert_match @user.microposts.count.to_s + " microposts", response.body
    
    # Make sure deleting a post deletes something and it isn't in the feed page.
    first_micropost = @user.microposts.paginate(page: 1).first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end
    
    # Visit a different user and make sure there are no delete links
    other_user = users(:archer)
    get user_path(other_user)
    other_user.feed.paginate(page: 1).each do |m|
      assert_select 'li[id=?]', "micropost-" + m.id.to_s
      #assert_match m.content, response.body
      assert_select 'a[href=?]', micropost_path(m), text: 'delete',
        count: m.user == @user ? 1 : 0
    end

  end
  
end
