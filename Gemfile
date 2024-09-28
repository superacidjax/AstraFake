source "https://rubygems.org"

gem "rails", "~> 7.2.1"
gem "puma", ">= 5.0"
gem "pg"
# Reduces boot times through caching; required in config/boot.rb
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
  gem "skylight"
end
group :test do
  gem "webmock"
end
