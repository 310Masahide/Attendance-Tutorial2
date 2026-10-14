FactoryBot.define do
  factory :office do
    sequence(:name) { |n| "拠点#{n}" }
    attendance_type { "出勤" }
  end
end
