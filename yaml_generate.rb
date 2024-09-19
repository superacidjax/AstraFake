require 'yaml'
require 'faker'
require 'uuid7'
require 'time'

class YamlPersonGenerator
  def self.generate_yaml_for_people
    file_path = File.join(__dir__, 'config', 'people.yml')

    unless File.exist?(file_path)
      puts "File doesn't exist. Creating #{file_path}..."
      File.open(file_path, 'w') { |f| f.write({ 'people' => [] }.to_yaml) }
    end

    d = YAML.load_file(file_path)

    50.times do
      person = {
        'user_id' => UUID7.generate,
        'traits' => {
          'firstName' => Faker::Name.first_name,
          'lastName' => Faker::Name.last_name,
          'gender' => ['male', 'female'].sample,
          'email' => Faker::Internet.email(domain: 'example.com'),
          'birthday' => Faker::Date.between(from: '1931-09-23', to: '2014-09-25').to_s,
          'phone' => Faker::PhoneNumber.cell_phone_in_e164,
          'address' => {
            'city' => Faker::Address.city,
            'state' => Faker::Address.state_abbr,
            'street' => Faker::Address.street_address,
            'postalCode' => Faker::Address.zip_code,
            'country' => 'US'
          },
          'createdAt' => Faker::Time.backward(days: 4000).iso8601,
          'hireDate' => Faker::Time.backward(days: 2300).iso8601,
          'currentBMI' => rand(17.00..41.00).round(2),
          'currentBpSystolic' => rand(110..180),
          'currentBpDiastolic' => rand(60..110),
          'currentWeightInKg' => rand(35..130),
          'currentWaistInCm' => rand(50.00..114.00).round(2),
          'currentGlucose' => rand(70..100).round(1),
          'currentA1c' => rand(4.0..8.00).round(2)
        },
        'timestamp' => Time.now.iso8601
      }

      d['people'] << person
    end

    File.open(file_path, 'w') { |f| f.write d.to_yaml }

    puts "50 people added to #{file_path}."
  end
end

class YamlEventGenerator
  def self.generate_yaml_for_events
    file_path = File.join(__dir__, 'config', 'events.yml')

    unless File.exist?(file_path)
      puts "File doesn't exist. Creating #{file_path}..."
      File.open(file_path, 'w') { |f| f.write({ 'events' => [] }.to_yaml) }
    end

    d = YAML.load_file(file_path)

    people_data = YAML.load_file(File.join(__dir__, 'config', 'people.yml'))
    user_ids = people_data['people'].map { |person| person['user_id'] }

    150.times do
      user_id = "<%= user_ids.sample %>"

      event_types = [
        'New User Created',
        'Screening Scheduled',
        'Screening Completed',
        'New Measurement',
        'Claim Received',
        'Lab Received',
        'Form Received',
        'Incentive Achieved'
      ]

      event_type = event_types.sample
      event = case event_type
              when 'New User Created'
                {
                  'event_type' => 'New User Created',
                  'user_id' => user_id,
                  'properties' => {
                    'source' => ['self-serve', 'imported', 'employer'].sample
                  },
                  'timestamp' => Faker::Time.between(from: Time.now - 3 * 365 * 24 * 60 * 60, to: Time.now).iso8601  # 3 years ago to now
                }
              when 'Screening Scheduled'
                {
                  'event_type' => 'Screening Scheduled',
                  'user_id' => user_id,
                  'properties' => {
                    'clinic_name' => Faker::Company.name,
                    'date_of_screening' => Faker::Time.between(from: Time.now, to: Time.now + 365 * 24 * 60 * 60).iso8601, # today to 1 year from now
                    'screening_type' => ['Annual', 'Initial', 'Specialty'].sample
                  },
                  'timestamp' => Faker::Time.between(from: Time.now - 6 * 30 * 24 * 60 * 60, to: Time.now).iso8601  # 6 months ago to now
                }
              when 'Screening Completed'
                {
                  'event_type' => 'Screening Completed',
                  'user_id' => user_id,
                  'properties' => {
                    'clinic_name' => Faker::Company.name,
                    'date_of_completion' => Faker::Time.between(from: Time.now, to: Time.now + 365 * 24 * 60 * 60).iso8601,
                    'screening_type' => ['Annual', 'Initial', 'Specialty'].sample
                  },
                  'timestamp' => Faker::Time.between(from: Time.now - 6 * 30 * 24 * 60 * 60, to: Time.now).iso8601
                }
              when 'New Measurement'
                measurement_types = ['BMI', 'blood pressure', 'weight', 'waist', 'glucose', 'a1c']
                measurement_type = measurement_types.sample

                properties = case measurement_type
                             when 'BMI'
                               { 'type' => 'BMI', 'bmi' => rand(17.0..41.0).round(2) }
                             when 'blood pressure'
                               { 'type' => 'blood pressure', 'systolic' => rand(110..180), 'diastolic' => rand(60..110) }
                             when 'weight'
                               { 'type' => 'weight', 'weight_in_kg' => rand(35..130) }
                             when 'waist'
                               { 'type' => 'waist', 'waist_in_cm' => rand(50.0..114.0).round(2) }
                             when 'glucose'
                               { 'type' => 'glucose', 'glucose' => rand(70..100).round(1) }
                             when 'a1c'
                               { 'type' => 'a1c', 'a1c' => rand(4.0..8.0).round(2) }
                             end

                {
                  'event_type' => 'New Measurement',
                  'user_id' => user_id,
                  'properties' => properties.merge({
                    'date_of_measurement' => Faker::Time.between(from: Time.now - 6 * 30 * 24 * 60 * 60, to: Time.now).iso8601
                  }),
                  'timestamp' => Faker::Time.between(from: Time.now - 6 * 30 * 24 * 60 * 60, to: Time.now).iso8601
                }
              when 'Claim Received'
                {
                  'event_type' => 'Claim Received',
                  'user_id' => user_id,
                  'properties' => {
                    'date_of_claim' => Faker::Time.between(from: Time.now - 6 * 30 * 24 * 60 * 60, to: Time.now).iso8601
                  },
                  'timestamp' => Faker::Time.between(from: Time.now - 6 * 30 * 24 * 60 * 60, to: Time.now).iso8601
                }
              when 'Lab Received'
                lab_tests = {
                  'CBC' => rand(50..200),
                  'Glucose' => rand(70..100).round(1),
                  'A1c' => rand(4.0..8.0).round(2)
                }
                test_type = lab_tests.keys.sample
                {
                  'event_type' => 'Lab Received',
                  'user_id' => user_id,
                  'properties' => {
                    'date_of_lab' => Faker::Time.between(from: Time.now - 6 * 30 * 24 * 60 * 60, to: Time.now).iso8601,
                    'test_type' => test_type,
                    'result' => lab_tests[test_type]
                  },
                  'timestamp' => Faker::Time.between(from: Time.now - 6 * 30 * 24 * 60 * 60, to: Time.now).iso8601
                }
              when 'Form Received'
                {
                  'event_type' => 'Form Received',
                  'user_id' => user_id,
                  'properties' => {
                    'type' => ['intake', 'medical record', 'release', 'other'].sample
                  },
                  'timestamp' => Faker::Time.between(from: Time.now - 6 * 30 * 24 * 60 * 60, to: Time.now).iso8601
                }
              when 'Incentive Achieved'
                {
                  'event_type' => 'Incentive Achieved',
                  'user_id' => user_id,
                  'properties' => {},
                  'timestamp' => Faker::Time.between(from: Time.now - 6 * 30 * 24 * 60 * 60, to: Time.now).iso8601
                }
              end

      d['events'] << event
    end

    File.open(file_path, 'w') { |f| f.write d.to_yaml }

    puts "150 events added to #{file_path}."
  end
end

# To generate the YAML files:
YamlPersonGenerator.generate_yaml_for_people
YamlEventGenerator.generate_yaml_for_events
