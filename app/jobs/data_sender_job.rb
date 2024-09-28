class DataSenderJob < ApplicationJob
  queue_as :default

  def perform
    if ENV["AUTO_SEND"] == "true" || Rails.env.test?
      data_sender = DataSender.new
      data_sender.send_random_event
    end
  end
end
