require 'test_helper'

class ApiControllerTest < ActionController::TestCase
  test "should get read" do
    get :read
    assert_response :success
  end

end
