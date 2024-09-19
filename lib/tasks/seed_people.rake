# rake data_sender:seed_people
namespace :data_sender do
  desc "Seed people data"
  task seed_people: :environment do
    data_sender = DataSender.new
    data_sender.seed_people
  end
end
