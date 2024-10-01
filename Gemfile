source "https://rubygems.org"

gem "rails", "~> 7.2.1"
gem "puma", ">= 5.0"
gem "pg"
gem "bootsnap", require: false
gem "faker"
gem "ostruct"
gem "good_job"

group :development, :test do
  gem "brakeman", require: false
  gem "pry-rails"
  gem "rubocop-rails-omakase", require: false
end

group :production do
  gem "stackprof"
  gem "sentry-ruby"
  gem "sentry-rails"
end

group :test do
  gem "simplecov", require: false
  gem "webmock"
end
