require 'test_helper'

class NovaApiConnectionTest < ActiveSupport::TestCase
  ACCESS_TOKEN_URL = "#{ENV["NOVA_API_BASE_URL"]}/#{ENV["NOVA_ACCESS_TOKEN_PATH"]}"

  def unauthorized_basic_auth_connection
    Faraday.new do |builder|
      builder.adapter :test do |stub|
        stub.get(ENV["NOVA_ACCESS_TOKEN_PATH"]) do |env|
          [403, {}, {"error" => "UNAUTHORIZED", "terminated" => true}.to_json ]
        end
      end
    end
  end

  test 'it raises an AuthenticationError with invalid credentials' do
    nova_api = NovaApiConnection.new
    nova_api.instance_variable_set(:@basic_auth_connection, unauthorized_basic_auth_connection)
    assert_raises NovaApiConnection::UnauthorizedError do
      nova_api.get_passport("123456")
    end
  end
end
