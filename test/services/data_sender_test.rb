require "test_helper"
require "webmock/minitest"

class DataSenderTest < ActiveSupport::TestCase
  def setup
    @people_data = [
      { "user_id" => "123", "traits" => { "firstName" => "John", "lastName" => "Doe" } }
    ]

    # Pass the people data directly to DataSender
    @data_sender = DataSender.new("test_api_secret", { "people" => @people_data })

    # Stub HTTP requests using WebMock
    WebMock.disable_net_connect!(allow_localhost: true)
    WebMock.stub_request(:any, /streamcamp-a2796efcaf71\.herokuapp\.com/).to_return(status: 200, body: "OK")
  end

  def teardown
    WebMock.allow_net_connect!
  end

  # Test for generating random event
  def test_generate_random_event_should_return_a_valid_event_structure
    user_id = "123"
    event = @data_sender.send(:generate_random_event, user_id)
    assert event["event_type"].present?
    assert event["user_id"].present?
    assert event["timestamp"].present?
  end

  # Test for sending random event
  def test_send_random_event_should_send_a_post_request_for_a_random_event
    @data_sender.send(:send_random_event)
    assert_requested :post, DataSender::EVENT_ENDPOINT, times: 1
  end

  # Test for seeding people
  def test_seed_people_should_send_a_post_request_for_each_person
    @data_sender.seed_people
    assert_requested :post, DataSender::PEOPLE_ENDPOINT, times: @people_data.size
  end

  # Test for generating lab result with correct values
  def test_generate_lab_result_should_return_valid_result_based_on_test_type
    # Directly test the generate_lab_result method
    glucose_result = @data_sender.send(:generate_lab_result, "Glucose")
    assert_includes 70..120, glucose_result, "Glucose result is out of range"

    a1c_result = @data_sender.send(:generate_lab_result, "A1c")
    assert_includes 4.5..6.5, a1c_result, "A1c result is out of range"

    cbc_result = @data_sender.send(:generate_lab_result, "CBC")
    assert_includes 55..180, cbc_result, "CBC result is out of range"
  end
end
