# frozen_string_literal: true
class NovaApiConnection
  CONNECTION_OPTIONS = {
    url: ENV["NOVA_API_BASE_URL"],
    headers: {
      # Specify the API environment (either "sandbox" or "production")
      "X-ENVIRONMENT" => ENV["NOVA_API_ENV"]
    }
  }

  # Fetch the credit passport for the supplied token. The token is sent via
  # the /nova webhook in ApplicationController, which is hit from Nova's
  # servers when a user completes Nova Connect
  def get_passport(public_token)
    response = bearer_connection.get(ENV["NOVA_PASSPORT_PATH"]) do |request|
      request.headers["X-PUBLIC-TOKEN"] = public_token
    end
    parse_body_and_check_for_errors(response)
  end

  private

  # Parses the response body as JSON, checks for error status and message,
  # then returns the parsed body.
  # May throw errors, if any are returned from the API
  def parse_body_and_check_for_errors(response)
    ActiveSupport::JSON.decode(response.body).tap do |json_response|
      check_response_for_errors(response.status, json_response)
    end
  end

  # Fetch an access token using Basic Auth credentials and store it for future
  # API requests.
  def access_token
    @access_token ||= begin
      response = basic_auth_connection.get(ENV["NOVA_ACCESS_TOKEN_PATH"])
      json_response = parse_body_and_check_for_errors(response)
      json_response["accessToken"]
    end
  end

  # Basic authentication HTTP connection, used for generating access tokens
  def basic_auth_connection
    @basic_auth_connection ||= begin
      Faraday.new(CONNECTION_OPTIONS) do |connection|
        connection.adapter Faraday.default_adapter
        connection.basic_auth(
          ENV["NOVA_SANDBOX_CLIENT_ID"],
          ENV["NOVA_SANDBOX_SECRET_KEY"])
      end
    end
  end

  # Bearer token authorized HTTP connection for API requests
  def bearer_connection
    @bearer_connection ||= begin
      Faraday.new(CONNECTION_OPTIONS) do |connection|
        connection.adapter Faraday.default_adapter
        connection.authorization :Bearer, Base64.strict_encode64(access_token)
      end
    end
  end

  # Check for API error response. This method only handles a subset of the
  # possibilities, for example purposes.
  # For the full list of possible errors, see the "Error Codes & Responses"
  # section of Nova API documentation:
  # https://docs.neednova.com/#error-codes-amp-responses
  def check_response_for_errors(response_status, response_json)
    case response_status
    when 200
      return true
    when 401
      if response_json["error"] == "EXPIRED_TOKEN"
        raise NovaApiConnection::ExpiredTokenError.new
      else
        raise NovaApiConnection::UnhandledErrorResponseError.new
      end
    when 403
      case response_json["error"]
      when "UNAUTHORIZED"
        raise NovaApiConnection::UnauthorizedError.new
      when "UNKNOWN_CUSTOMER"
        raise NovaApiConnection::UnknownCustomerError.new
      when "ORIGIN_UNAUTHORIZED"
        raise NovaApiConnection::OriginUnauthorizedError.new
      else
        raise NovaApiConnection::UnhandledErrorResponseError.new
      end
    end
  end

  # Error classes for API responses
  # For the full list of possible errors, see the "Error Codes & Responses"
  # section of Nova API documentation:
  # https://docs.neednova.com/#error-codes-amp-responses
  class UnauthorizedError < StandardError
    def message
      "The client_id and secret_key combination is not recognized."
    end
  end

  class UnknownCustomerError < UnauthorizedError
    def message
      "The public_id or client_id were not recognized"
    end
  end
  class OriginUnauthorizedError < UnauthorizedError
    def message
      "The origin of the request is not whitelisted on the Nova servers \
          for CORS"
    end
  end

  class ExpiredTokenError < UnauthorizedError;
    def message
      "This access token has expired. Please request a new one."
    end
  end

  # For error responses we don't expect, raise a specific error rather than
  # swallowing it.
  class UnhandledErrorResponseError < StandardError; end
end
