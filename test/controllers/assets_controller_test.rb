require "test_helper"

class AssetsControllerTest < ActionDispatch::IntegrationTest
  test "should get verify_and_update" do
    get assets_verify_and_update_url
    assert_response :success
  end
end
