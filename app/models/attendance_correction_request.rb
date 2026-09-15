class AttendanceCorrectionRequest < ApplicationRecord
  belongs_to :attendance
  belongs_to :user
  belongs_to :approver, class_name: "User"

  enum status: { unset: 0, pending: 1, approved: 2, rejected: 3 }

  scope :awaiting_decision, -> { where(status: [:pending, :unset]) }

  validates :attendance_id, uniqueness: true
  validate :approver_must_be_another_supervisor
  validate :requested_started_at_and_finished_at_must_be_both_or_neither
  validate :requested_started_at_than_requested_finished_at_fast_if_invalid

  after_update :apply_to_attendance, if: -> { saved_change_to_status? && approved? }

  def editable?
    pending? || rejected?
  end

  def decided?
    approved? || rejected?
  end

  def status_label
    I18n.t("activerecord.attributes.attendance_correction_request.statuses.#{status}")
  end

  def self.status_options
    statuses.keys.map { |status_name| [I18n.t("activerecord.attributes.attendance_correction_request.statuses.#{status_name}"), status_name] }
  end

  def result_label
    approved? ? "勤怠編集承認済" : "勤怠編集否認"
  end

  private

    def approver_must_be_another_supervisor
      return if approver.nil?

      errors.add(:approver, "は上長を指定してください") unless approver.supervisor?
      errors.add(:approver_id, "には自分自身を指定できません") if approver_id.present? && approver_id == user_id
    end

    def requested_started_at_and_finished_at_must_be_both_or_neither
      return if requested_started_at.present? == requested_finished_at.present?

      errors.add(:base, "出社時間と退社時間は両方入力するか、両方空欄にしてください")
    end

    def requested_started_at_than_requested_finished_at_fast_if_invalid
      return if requested_started_at.blank? || requested_finished_at.blank?

      errors.add(:requested_started_at, "より早い退社時間は無効です") if requested_started_at > requested_finished_at
    end

    # 承認された瞬間に、実際のAttendanceへ反映します。
    def apply_to_attendance
      attendance.update!(started_at: requested_started_at, finished_at: requested_finished_at, note: note)
    end
end
