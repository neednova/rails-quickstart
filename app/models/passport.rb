require 'active_model'

class Passport
  # A simple class to wrap the Nova Credit Passport data returned from the API.

  include ActiveModel::Model

  NOVA_SCORE_TYPE_BETA = "NOVA_SCORE_BETA".freeze

  # These are the attributes from the Nova API that we want to save
  # For a full explaination of the Nova Credit Passport, please reference the
  # Nova API documentation: See https://docs.neednova.com/
  API_ATTRIBUTES = [
    :personal, :meta, :product, :scores, :currencies, :tradelines, :addresses,
    :employers, :other_incomes, :inquiries, :identifiers, :bank_accounts,
    :public_records, :frauds, :other_assets, :collections, :nonsufficient_funds,
    :disputes, :notices, :metrics
  ].freeze

  attr_accessor *API_ATTRIBUTES

  def nova_score
    @nova_score ||= begin
      self.scores.find { |score| score["score_type"] == NOVA_SCORE_TYPE_BETA }
    end
  end
end
