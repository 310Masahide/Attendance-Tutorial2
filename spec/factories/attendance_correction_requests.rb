FactoryBot.define do
  factory :attendance_correction_request do
    attendance
    user { attendance.user }
    association :approver, factory: :user, supervisor: true
    requested_started_at { Time.zone.local(2026, 1, 1, 9, 0) }
    requested_finished_at { Time.zone.local(2026, 1, 1, 18, 0) }
    status { :pending }
  end
end
