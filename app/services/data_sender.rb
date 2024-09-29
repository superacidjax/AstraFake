require "net/http"
require "uri"
require "yaml"
require "faker"
require "securerandom"

class DataSender
  PEOPLE_ENDPOINT = "https://astrastream-f88676dd5abc.herokuapp.com/api/v1/people"
  EVENT_ENDPOINT = "https://astrastream-f88676dd5abc.herokuapp.com/api/v1/events"

  def initialize(api_secret = Rails.application.credentials[:astra_stream_api_secret], people_data = nil)
    # Load the people data from the YAML file
    @people_data = people_data || YAML.load_file(Rails.root.join("config", "people.yml"))
    @api_secret = api_secret
  end

  def seed_people
    @people_data["people"].each do |person|
      send_post_request("person" => person)
    end
  end

  def send_random_event
    person = pick_random_person
    event = generate_random_event(person["user_id"])
    send_event_post_request(event)
  end

  private

  def pick_random_person
    @people_data["people"].sample
  end

  def generate_random_event(user_id)
    event_types = [
      "New User Created", "Screening Scheduled", "Screening Completed",
      "New Measurement", "Claim Received", "Lab Received", "Form Received",
      "Incentive Achieved"
    ]

    event_type = event_types.sample

    case event_type
    when "New User Created"
      {
        "event_type" => "New User Created",
        "user_id" => user_id,
        "properties" => {
          "source" => [ "self-serve", "imported", "employer" ].sample
        },
        "timestamp" => Faker::Time.between(from: 3.years.ago, to: Time.now).iso8601
      }
    when "Screening Scheduled"
      {
        "event_type" => "Screening Scheduled",
        "user_id" => user_id,
        "properties" => {
          "clinic_name" => Faker::Company.name,
          "date_of_screening" => Faker::Time.between(from: Time.now, to: 1.year.from_now).iso8601,
          "screening_type" => [ "Annual", "Initial", "Specialty" ].sample
        },
        "timestamp" => Faker::Time.between(from: 6.months.ago, to: Time.now).iso8601
      }
    when "Screening Completed"
      {
        "event_type" => "Screening Completed",
        "user_id" => user_id,
        "properties" => {
          "clinic_name" => Faker::Company.name,
          "date_of_completion" => Faker::Time.between(from: Time.now, to: 1.year.from_now).iso8601,
          "screening_type" => [ "Annual", "Initial", "Specialty" ].sample
        },
        "timestamp" => Faker::Time.between(from: 6.months.ago, to: Time.now).iso8601
      }
    when "New Measurement"
      {
        "event_type" => "New Measurement",
        "user_id" => user_id,
        "properties" => {
          "type" => "BMI",
          "date_of_measurement" => Faker::Time.between(from: 6.months.ago, to: Time.now).iso8601,
          "bmi" => rand(17.00..41.00).round(2)
        },
        "timestamp" => Faker::Time.between(from: 6.months.ago, to: Time.now).iso8601
      }
    when "Claim Received"
      {
        "event_type" => "Claim Received",
        "user_id" => user_id,
        "properties" => {
          "date_of_claim" => Faker::Time.between(from: 6.months.ago, to: Time.now).iso8601
        },
        "timestamp" => Faker::Time.between(from: 6.months.ago, to: Time.now).iso8601
      }
    when "Lab Received"
      test_type = [ "CBC", "Glucose", "A1c" ].sample
      {
        "event_type" => "Lab Received",
        "user_id" => user_id,
        "properties" => {
          "date_of_lab" => Faker::Time.between(from: 6.months.ago, to: Time.now).iso8601,
          "test_type" => test_type,
          "result" => generate_lab_result(test_type)
        },
        "timestamp" => Faker::Time.between(from: 6.months.ago, to: Time.now).iso8601
      }
    when "Form Received"
      {
        "event_type" => "Form Received",
        "user_id" => user_id,
        "properties" => {
          "type" => [ "intake", "medical record", "release", "other" ].sample
        },
        "timestamp" => Faker::Time.between(from: 6.months.ago, to: Time.now).iso8601
      }
    when "Incentive Achieved"
      {
        "event_type" => "Incentive Achieved",
        "user_id" => user_id,
        "properties" => {},
        "timestamp" => Faker::Time.between(from: 6.months.ago, to: Time.now).iso8601
      }
    end
  end

  def generate_lab_result(test_type)
    case test_type
    when "CBC"
      rand(55..180) # Adjust for CBC realistic range
    when "Glucose"
      rand(70..120) # Adjust for Glucose realistic range
    when "A1c"
      rand(4.5..6.5).round(2) # Adjust for A1c realistic range
    end
  end

  def send_post_request(person)
    uri = URI.parse(PEOPLE_ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(@api_secret, "")
    request.content_type = "application/json"
    request.body = person.to_json

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    response = http.request(request)

    puts "Response Code: #{response.code}"
    puts "Response Body: #{response.body}"
  end

  def send_event_post_request(event)
    uri = URI.parse(EVENT_ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(@api_secret, "")
    request.content_type = "application/json"
    request.body = event.to_json

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    response = http.request(request)

    puts "Response Code: #{response.code}"
    puts "Response Body: #{response.body}"
  end
end
