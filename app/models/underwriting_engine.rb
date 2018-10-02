class UnderwritingEngine
  APPROVE_VALUE = "APPROVE".freeze
  DENIAL_VALUE = "DENY".freeze
  NOVA_SCORE_LOAN_DECISION_THRESHOLD = 650

  attr_accessor :credit_passport

  def initialize(credit_passport)
    @credit_passport = credit_passport
  end

  # Your underwriting engine will probably be a bit more nuanced. Here we're
  # just checking that Nova's BETA Score is above a certain threshold
  def analyze!
    if nova_score_above_threshold?
      APPROVE_VALUE
    else
      DENIAL_VALUE
    end
  end

  private

  def nova_score_above_threshold?
    credit_passport.nova_score &&
    credit_passport.nova_score["value"] > NOVA_SCORE_LOAN_DECISION_THRESHOLD
  end
end
