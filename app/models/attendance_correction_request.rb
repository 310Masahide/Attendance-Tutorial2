class AttendanceCorrectionRequest < ApplicationRecord
  include ApproverValidatable
  include StatusPresentable

  belongs_to :attendance
  belongs_to :user
  belongs_to :approver, class_name: "User"

  validates :attendance_id, uniqueness: { conditions: -> { awaiting_decision } }
  validates :note, length: { maximum: Attendance::NOTE_MAX_LENGTH }
  validate :requested_started_at_and_finished_at_must_be_both_or_neither
  validate :requested_started_at_must_be_before_requested_finished_at

  after_update :apply_to_attendance, if: -> { saved_change_to_status? && approved? }

  def result_label
    approved? ? "勤怠編集承認済" : "勤怠編集否認"
  end

  private

    def requested_started_at_and_finished_at_must_be_both_or_neither
      return if requested_started_at.present? == requested_finished_at.present?

      errors.add(:base, "出社時間と退社時間は両方入力するか、両方空欄にしてください")
    end

    def requested_started_at_must_be_before_requested_finished_at
      return if requested_started_at.blank? || requested_finished_at.blank?

      errors.add(:requested_started_at, "より早い退社時間は無効です") if requested_started_at > requested_finished_at
    end

    # 承認された瞬間に、実際のAttendanceへ反映します。(16行目のafter_updateから呼ばれます)
    def apply_to_attendance
      attendance.lock!
      attendance.update!(started_at: requested_started_at, finished_at: requested_finished_at, note: note)
    end
end
