require "net/http"
require "uri"
require "yaml"
require "faker"
require "securerandom"

class DataSender
  def initialize(api_secret = Rails.application.credentials[:astra_stream_api_secret], people_data = nil)
    @people_data = people_data || YAML.load_file(Rails.root.join("config", "people.yml"))
    @api_secret = api_secret
    @seeds_file_path = Rails.root.join("db", "seeds.rb")
  end

  def seed_people
    File.open(@seeds_file_path, "w") do |file|
      file.puts("# Seed file generated by DataSender")
      file.puts("# Generated at #{Time.now}")
      file.puts("")

      @people_data["people"].each do |person|
        write_person_to_seed(file, person)
      end
    end

    Rails.logger.debug { "Seed file created at #{@seeds_file_path}" }
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
      rand(55..180)
    when "Glucose"
      rand(70..120)
    when "A1c"
      rand(4.5..6.5).round(2)
    end
  end

  def write_person_to_seed(file, person_data)
    file.puts("person = Person.find_or_create_by!(client_user_id: '#{person_data['user_id']}') do |p|")
    file.puts("  p.client_timestamp = '#{person_data['timestamp']}'")
    file.puts("  p.account_id = 'XXXXX'")
    file.puts("end")
    file.puts("")

    person_data["traits"].each do |key, value|
      type = infer_type(value)
      file.puts("trait = Trait.find_or_create_by!(name: '#{key}', account_id: person.account_id, value_type: '#{type}')")
      file.puts("trait.client_applications << ClientApplication.find_by!(application_id: '#{person_data['context']['application_id']}')")
      file.puts("TraitValue.create!(trait_id: trait.id, person_id: person.id, data: '#{value}')")
      file.puts("")
    end
  end

  def infer_type(value)
    case value
    when /\A\d+(\.\d+)?\z/
      "numeric"
    when /\Atrue\z/i, /\Afalse\z/i
      "boolean"
    when /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z\z/
      "datetime"
    else
      "text"
    end
  end

  def send_post_request(person)
    uri = URI.parse("#{ASTRA_STREAM_URL}/people")

    Rails.logger.debug { "Sending POST request to URI: #{uri}" }
    Rails.logger.debug { "Person data being sent: #{person.to_json}" }

    request = Net::HTTP::Post.new(uri)
    request.basic_auth(@api_secret, "")
    request.content_type = "application/json"
    request.body = person.to_json

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true unless Rails.env.test? || Rails.env.development?

    Rails.logger.debug { "HTTP headers: #{request.to_hash}" }

    begin
      response = http.request(request)
      Rails.logger.debug { "Response Code: #{response.code}" }
      Rails.logger.debug { "Response Body: #{response.body}" }
    rescue StandardError => e
      Rails.logger.error { "Error sending POST request: #{e.message}" }
      raise
    end
  end

  def send_event_post_request(event)
    uri = URI.parse("#{ASTRA_STREAM_URL}/events")
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(@api_secret, "")
    request.content_type = "application/json"
    request.body = event.to_json

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true unless Rails.env.test? || Rails.env.development?

    begin
      response = http.request(request)
      Rails.logger.debug { "Response Code: #{response.code}" }
      Rails.logger.debug { "Response Body: #{response.body}" }
    rescue StandardError => e
      Rails.logger.error { "Error sending POST request: #{e.message}" }
      raise
    end
  end
end
