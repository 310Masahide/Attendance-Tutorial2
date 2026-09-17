class OvertimeRequest < ApplicationRecord
  belongs_to :user
  belongs_to :approver, class_name: "User"

  enum status: { unset: 0, pending: 1, approved: 2, rejected: 3 }

  scope :awaiting_decision,   -> { where(status: [:pending, :unset]) }

  validates :worked_on, presence: true
  validates :finished_hour, presence: true, inclusion: { in: 0..23 }
  validates :finished_minute, presence: true, inclusion: { in: 0..59 }
  validates :content, presence: true
  validates :worked_on, uniqueness: { scope: :user_id}
  validate :approver_must_be_another_supervisor

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

  def status_label
    I18n.t("activerecord.attributes.overtime_request.statuses.#{status}")
  end

  def decided?
    approved? || rejected?
  end

  def editable?
    pending? || rejected?
  end

  def self.status_options
    statuses.keys.map { |status_name| [I18n.t("activerecord.attributes.overtime_request.statuses.#{status_name}"), status_name] }
  end

  def approver_must_be_another_supervisor
    return if approver.nil?

    errors.add(:approver, "は上長を指定してください") unless approver.supervisor?
    errors.add(:approver_id, "には自分自身を指定できません") if approver_id.present? && approver_id == user_id
  end
end
