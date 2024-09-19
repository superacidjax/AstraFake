class DataSenderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    data_sender = DataSender.new
    data_sender.send_random_event
  end
end
