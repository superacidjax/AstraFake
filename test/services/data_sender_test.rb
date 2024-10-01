require "test_helper"
require "webmock/minitest"

class DataSenderTest < ActiveSupport::TestCase
  def setup
    WebMock.disable_net_connect!(allow_localhost: false)
    WebMock.reset! # Reset WebMock to clear previous requests

    @people_data = [
      { "user_id" => "123", "traits" => { "firstName" => "John", "lastName" => "Doe" }, "timestamp" => "2023-10-25T23:48:46+00:00", "context" => { "application_id" => "94948" } }
    ]

    @data_sender = DataSender.new("test_api_secret", { "people" => @people_data })

    # Stub POST requests to the local Astra stream URL
    WebMock.stub_request(:post, %r{http://localhost:3001/api/v1/people})
      .to_return(status: 200, body: "OK")
    WebMock.stub_request(:post, %r{http://localhost:3001/api/v1/events})
      .to_return(status: 200, body: "OK")
  end

  def teardown
    WebMock.reset! # Ensure WebMock is reset after each test
    WebMock.allow_net_connect!
  end

  def test_generate_random_event_should_return_a_valid_event_structure
    user_id = "123"
    event = @data_sender.send(:generate_random_event, user_id)
    assert event["event_type"].present?
    assert event["user_id"].present?
    assert event["timestamp"].present?
  end

  def test_send_random_event_should_send_a_post_request_for_a_random_event
    @data_sender.send_random_event
    assert_requested :post, %r{http://localhost:3001/api/v1/events}, times: 1
  end

  def test_seed_people_should_generate_a_seed_file_with_people_data
    @data_sender.seed_people
    seed_file_content = File.read(Rails.root.join("seeds.rb"))

    assert_includes seed_file_content, "person = Person.find_or_create_by!(client_user_id: '123')"
    assert_includes seed_file_content, "p.client_timestamp = '2023-10-25T23:48:46+00:00'"
    assert_includes seed_file_content, "Trait.find_or_create_by!(name: 'firstName'"
    assert_includes seed_file_content, "Trait.find_or_create_by!(name: 'lastName'"
    assert_includes seed_file_content, "TraitValue.create!"
  end

  def test_generate_lab_result_should_return_valid_result_based_on_test_type
    glucose_result = @data_sender.send(:generate_lab_result, "Glucose")
    assert_includes 70..120, glucose_result, "Glucose result is out of range"

    a1c_result = @data_sender.send(:generate_lab_result, "A1c")
    assert_includes 4.5..6.5, a1c_result, "A1c result is out of range"

    cbc_result = @data_sender.send(:generate_lab_result, "CBC")
    assert_includes 55..180, cbc_result, "CBC result is out of range"
  end

  def test_send_post_request_should_send_a_post_request_for_person
    person = @people_data.first
    @data_sender.send(:send_post_request, person)
    assert_requested :post, %r{http://localhost:3001/api/v1/people}, times: 1
  end
end
