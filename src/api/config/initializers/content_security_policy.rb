# Allow webpack-dev-server host as allowed origin for connect-src (as suggested when installing Webpacker)
Rails.application.config.content_security_policy do |policy|
  policy.connect_src :self, :https, 'http://localhost:3035', 'ws://localhost:3035' if Rails.env.development?
end
