# Be sure to restart your server when you modify this file.
#Rails.application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 30.minutes, key:  '_contactrocket_session', domain: ".your-server.net"
Rails.application.config.session_store :cookie_store, key:  '_contactrocket_session', domain: ENV['DOMAIN_NAME']
