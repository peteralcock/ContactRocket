# Require this file using `require "spec_helper"`
# to ensure that it is only loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'digest/md5'
require 'coveralls'
require 'vcr'
require 'webmock/rspec'

Coveralls.wear!

require 'polipus'

VCR.configure do |c|
  c.cassette_library_dir = "#{File.dirname(__FILE__)}/cassettes"
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
  c.ignore_localhost = true
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
  config.mock_with :flexmock
  config.around(:each) do |example|
    t = Time.now
    print example.metadata[:full_description]
    VCR.use_cassette(
      Digest::MD5.hexdigest(example.metadata[:full_description]),
      record: :all
    ) do
      example.run
    end
    puts " [#{Time.now - t}s]"
  end
  config.before(:each) { Polipus::SignalHandler.disable }
end

def page_factory(url, params = {})
  params[:code] ||= 200 unless params.has_key?(:code)
  params[:body] = '<html></html>' unless params.has_key?(:body)
  params[:fetched_at] = Time.now.to_i
  sleep(1)
  Polipus::Page.new(url, params)
end
