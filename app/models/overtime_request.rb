class OvertimeRequest < ApplicationRecord
  belongs_to :user
  belongs_to :approver, class_name: "User"

  enum status: { pending: 0, approved: 1, rejected: 2, unset: 3 }

  validates :worked_on, presence: true
  validates :finished_hour, presence: true, inclusion: { in: 0..23 }
  validates :finished_minute, presence: true, inclusion: { in: 0..59 }
  validates :content, presence: true

  # 「翌日」チェック込みの実際の終了予定日時が必要な場合はここで計算
  def finished_on
    next_day? ? worked_on + 1.day : worked_on
  end

  def overtime_hours
    standard_minutes = user.work_time.hour * 60 + user.work_time.min
    finished_minutes = finished_hour * 60 + finished_minute + (next_day? ? 24 * 60 : 0)
    ((finished_minutes - standard_minutes) / 60.0).round(2)
  end

  def result_label
    return "残業承認済" if approved?
    return "残業否認" if rejected?
  end

  def status_label
    case status
    when "pending"  then "残業申請中"
    when "approved" then "残業承認済"
    when "rejected" then "残業否認"
    when "unset"    then "未定"
    end
  end

  scope :unconfirmed_results, -> { where(status: [:approved, :rejected], applicant_confirmed: false) }

end
