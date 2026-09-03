FactoryBot.define do
  factory :attendance do
    user
    worked_on { Date.current }
  end
end
