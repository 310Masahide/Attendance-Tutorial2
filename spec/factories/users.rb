FactoryBot.define do
  factory :user do
    name {  Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password' }
    password_confirmation { 'password' }
    created_at { "2023-12-31T17:05:48.618+09:00" }
    updated_at { "2024-01-03T18:01:26.857+09:00" }
    admin { false }
    department { Faker::Job.field }
    basic_time { "2024-01-03T08:00:00.000+09:00" }
    work_time { "2024-01-03T07:30:00.000+09:00" }
  end
end