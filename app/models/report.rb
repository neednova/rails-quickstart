require 'active_model'

class Report
  include ActiveModel::Model

  REPORT_DATA_PATH = Rails.root.join("tmp/report_data.json")

  attr_accessor :user_args, :public_token, :loan_decision, :passport

  # For simple, example purposes only, we're storing data in a temporary
  # file to reduce dependencies and simplify setup.
  #
  # Your application will likely store this information in a database or another
  # service.
  def self.first
    report_data_from_file
  end

  # Generate report data based on the credit passport data returned from Nova.
  # We merge this information with a loan decision from our application's
  # underwriting engine's analysis
  def self.store_passport_from_api(raw_api_response, user_args, public_token)
    user_credit_passport = Passport.new(raw_api_response)
    loan_decision = UnderwritingEngine.new(user_credit_passport).analyze!
    write_report_data({
      user_args: user_args,
      public_token: public_token,
      loan_decision: loan_decision,
      passport: user_credit_passport
    })
  end

  private

  # Check to see if the report data exists. If it does, read it and reify
  # the report and passport data into new objects
  def self.report_data_from_file
    if File.exists?(REPORT_DATA_PATH)
      report_data_as_json = File.open(REPORT_DATA_PATH) { |file| file.read }
      report_data = ActiveSupport::JSON.decode(report_data_as_json)
      report_data["passport"] = Passport.new(report_data["passport"].except("nova_score"))
      Report.new(report_data)
    end
  end

  # Serialize the report into json and store for later use (in this app, we
  # can view it at `/dashboard`)
  def self.write_report_data(report_data)
    File.open(REPORT_DATA_PATH, "w+") do |file|
      file.write(report_data.to_json)
    end
  end
end
