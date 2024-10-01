if Rails.env.production?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

    # comment this at higher scale
    config.traces_sample_rate = 1.0

    # uncomment this at higher scale
    # config.traces_sampler = lambda do |context|
    #   true
    # end

    # adjust this at higher scale as well 1.0 = 100% 0.9 = 90% etc.
    config.profiles_sample_rate = 1.0
  end
end
