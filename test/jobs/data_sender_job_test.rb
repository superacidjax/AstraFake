require "test_helper"
require "webmock/minitest"
require "minitest/mock"

class DataSenderJobTest < ActiveJob::TestCase
  def setup
    WebMock.disable_net_connect!(allow_localhost: true)
    WebMock.reset! # Reset WebMock to clear previous requests

    astra_stream_url = ENV.fetch("ASTRA_STREAM_URL", "http://localhost:3001/api/v1")
    events_endpoint = "#{astra_stream_url}/events"

    WebMock.stub_request(:post, %r{#{events_endpoint}})
           .to_return(status: 200, body: "OK")
  end

  def teardown
    WebMock.allow_net_connect!
  end

  test "should perform the job and call send_random_event on DataSender" do
    mock_data_sender = Minitest::Mock.new
    mock_data_sender.expect :send_random_event, nil

    DataSender.stub :new, mock_data_sender do
      DataSenderJob.perform_now
    end

    assert_mock mock_data_sender
  end

  test "should enqueue and perform the job" do
    assert_enqueued_jobs 1 do
      DataSenderJob.perform_later
    end

    perform_enqueued_jobs

    astra_stream_url = ENV.fetch("ASTRA_STREAM_URL", "http://localhost:3001/api/v1")
    events_endpoint = "#{astra_stream_url}/events"

    assert_requested :post, %r{#{events_endpoint}}, times: 1
  end
end
