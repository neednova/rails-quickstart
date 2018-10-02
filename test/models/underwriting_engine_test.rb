require 'test_helper'

class UnderwritingEngineTest < ActiveSupport::TestCase
  test "it denies a score below the threshold" do
    definitive_welch = Passport.new({
      "scores" => [
          {
            "score_type" => Passport::NOVA_SCORE_TYPE_BETA,
            "value" => UnderwritingEngine::NOVA_SCORE_LOAN_DECISION_THRESHOLD - 1
          }
        ]
      })
    loan_decision = UnderwritingEngine.new(definitive_welch).analyze!
    assert loan_decision == UnderwritingEngine::DENIAL_VALUE
  end

  test "it denies a score equal to the threshold" do
    borderline_welch = Passport.new({
      "scores" => [
          {
            "score_type" => Passport::NOVA_SCORE_TYPE_BETA,
            "value" => UnderwritingEngine::NOVA_SCORE_LOAN_DECISION_THRESHOLD
          }
        ]
      })
    loan_decision = UnderwritingEngine.new(borderline_welch).analyze!
    assert loan_decision == UnderwritingEngine::DENIAL_VALUE
  end

  test "it approves a score above the threshold" do
    lannister = Passport.new({
      "scores" => [
          {
            "score_type" => Passport::NOVA_SCORE_TYPE_BETA,
            "value" => UnderwritingEngine::NOVA_SCORE_LOAN_DECISION_THRESHOLD + 1
          }
        ]
      })
    loan_decision = UnderwritingEngine.new(lannister).analyze!
    assert loan_decision == UnderwritingEngine::APPROVE_VALUE
  end
end
