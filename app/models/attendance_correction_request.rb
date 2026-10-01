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

  CorrectionLog = Struct.new(:worked_on, :before_started_at, :before_finished_at,
                             :after_started_at, :after_finished_at, :approver, :approved_at, keyword_init: true)

  # 勤怠修正ログ(承認済み)
  # 同じ日を複数回変更している場合は、一番最初に申請した変更前 ⇨ 一番最後に申請した変更後 にまとめます
  def self.correction_logs
    approved.includes(:attendance, :approver).order(:created_at)
            .group_by(&:attendance)
            .map do |attendance, requests|
              first_request = requests.first
              last_request  = requests.last
              CorrectionLog.new(worked_on:          attendance.worked_on,
                                before_started_at:  first_request.original_started_at,
                                before_finished_at: first_request.original_finished_at,
                                after_started_at:   last_request.requested_started_at,
                                after_finished_at:  last_request.requested_finished_at,
                                approver:           last_request.approver,
                                approved_at:        last_request.approved_at)
            end
            .sort_by(&:worked_on)
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

    # (変更前)と承認日を記録しておきます。(16行目のafter_updateから呼ばれます)
    # 勤怠修正ログのため、反映する直前の時刻(変更前)を記録しておきます
    def apply_to_attendance
      attendance.lock!
      update_columns(original_started_at: attendance.started_at,
                     original_finished_at: attendance.finished_at,
                     approved_at: Time.current)
      attendance.update!(started_at: requested_started_at, finished_at: requested_finished_at, note: note)
    end
end
