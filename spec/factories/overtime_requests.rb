FactoryBot.define do
  factory :overtime_request do
    user
    association :approver, factory: :user, supervisor: true
    worked_on { Date.current }
    finished_hour { 20 }
    finished_minute { 0 }
    finishes_next_day { false }
    content { "テスト残業内容" }
  end
end
