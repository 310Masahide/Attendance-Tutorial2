FactoryBot.define do
  factory :monthly_approval do
    user
    association :approver, factory: :user, supervisor: true
    month { Date.current.beginning_of_month }
    status { :pending }
  end
end
