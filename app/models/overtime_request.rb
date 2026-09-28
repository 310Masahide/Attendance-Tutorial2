class OvertimeRequest < ApplicationRecord
  include ApproverValidatable
  include StatusPresentable

  belongs_to :user
  belongs_to :approver, class_name: "User"

  validates :worked_on, presence: true
  validates :finished_hour, presence: true, inclusion: { in: 0..23 }
  validates :finished_minute, presence: true, inclusion: { in: 0..59 }
  validates :content, presence: true
  validates :worked_on, uniqueness: { scope: :user_id}

  def scheduled_finish_time
    user.designated_work_end_time
  end

  def overtime_minutes
    scheduled_finish_minutes = scheduled_finish_time.hour * 60 + scheduled_finish_time.min
    planned_finish_minutes   = finished_hour * 60 + finished_minute + (finishes_next_day? ? 24 * 60 : 0)

    [planned_finish_minutes - scheduled_finish_minutes, 0].max
  end

  def overtime_hours
    (overtime_minutes / 60.0).round(2)
  end

  # 承認済み以外(申請中・否認・差し戻し(なし))は、申請者本人が編集(再申請)できる
  def editable?
    !approved?
  end
end
