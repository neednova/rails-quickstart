# frozen_string_literal: true
class ApplicationController < ActionController::Base
  HOMEPAGE_TITLE = "Borrow Sample Loan Website"
  DASHBOARD_TITLE = "Dashboard for Borrow Loan Company"

  before_action :read_passport_data, only: :dashboard
  # We skip CSRF verification on the callback because Nova's servers aren't
  # submitting a form. In production, we would want to limit the accessibility
  # of this endpoint to prevent random data submissions into our system
  skip_before_action :verify_authenticity_token, only: [:nova]

  def home
    @page_title = HOMEPAGE_TITLE
    @nova_public_id = ENV["NOVA_SANDBOX_PUBLIC_ID"]
    @nova_product_id = ENV["NOVA_SANDBOX_PRODUCT_ID"]
    @nova_env = ENV["NOVA_API_ENV"]
    @user_args = "Customer_id_from_your_system"
  end

  def dashboard
    @page_title = DASHBOARD_TITLE
  end

  # This is the callback that Nova's servers call when someone completes
  # Nova Connect. We'll need to make additional API calls with the data we
  # received, so we drop into a background job and return a 200 immediately.
  # This frees up the HTTP connection on both of our servers.
  def nova
    NewNovaConnectJob.perform_later(
      params["publicToken"],
      params["status"],
      params["userArgs"]
    )
    head 200
  end

  private

  def read_passport_data
    @received_report_data = Report.first
  end
end
