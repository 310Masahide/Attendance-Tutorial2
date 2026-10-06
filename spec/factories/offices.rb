FactoryBot.define do
  factory :office do
    sequence(:office_number) { |n| n }
    sequence(:name) { |n| "拠点#{n}" }
    office_type { "出勤" }
  end
end
