require "faraday"
class NewNovaConnectJob < ActiveJob::Base
  queue_as :default

  # This is where we handle a new Nova Connect. Nova will inform us even if the
  # connect was unsuccessful, so we check its status before deciding what to do
  def perform(public_token, connect_status, user_args)
    if connect_status == "SUCCESS"
      # For this example application, we pull the user's Nova Passport, feed
      # it into our own report generator, and store that report.
      nova_passport_info = nova_api_connection.get_passport(public_token)
      Report.store_passport_from_api(nova_passport_info, user_args, public_token)
    else
      # In this case, the connect was a failure. We log it here, but your
      # application logic will likely differ.
      # For details on failure states, see the Nova API documentation:
      # https://docs.neednova.com/#data-types-amp-formats
      Rails.logger.log("Nova connection failed with status: #{connect_status}")
    end
  end

  private

  def nova_api_connection
    @nova_api_connection ||= NovaApiConnection.new
  end
end
