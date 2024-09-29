require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AstraFake
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Good Job Chron
    config.good_job.enable_cron = ENV["DYNO"] == "worker.1"

    config.good_job.enable_cron = true

    # Configure cron with a hash that has a unique key for each recurring job
    config.good_job.cron = {
      # Every 15 minutes, enqueue `ExampleJob.set(priority: -10).perform_later(42, "life", name: "Alice")`
      # frequent_task: { # each recurring job must have a unique key
      #   cron: "*/15 * * * *", # cron-style scheduling format by fugit gem
      #   class: "DataSenderJob", # name of the job class as a String; must reference an Active Job job class
      #   description: "Data Sender Job", # optional description that appears in Dashboard
      # },
      production_task: {
        cron: "*/1 * * * *", # cron-style scheduling format by fugit gem
        class: "DataSenderJob",
        enabled_by_default: -> { Rails.env.production? } # Only enable in production, otherwise can be enabled manually through Dashboard
      }
    }

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
