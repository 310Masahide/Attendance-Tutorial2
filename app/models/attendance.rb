class Attendance < ApplicationRecord
  belongs_to :user
  has_many :correction_requests, class_name: "AttendanceCorrectionRequest", dependent: :destroy

  # 履歴の中から「今表示すべき最新の申請」を1件返します(申請中でも決着済みでもOK)。
  def correction_request
    correction_requests.max_by(&:created_at)
  end

  validates :worked_on, presence: true
  validates :note, length: { maximum: 50 }

  validate :finished_at_is_invalid_without_a_started_at
  validate :started_at_must_be_before_finished_at

  def started_at_hour;   started_at&.hour; end
  def started_at_minute; started_at&.min;  end
  def finished_at_hour;  finished_at&.hour; end
  def finished_at_minute; finished_at&.min; end

  def finishes_next_day?
    finished_at.present? && finished_at.to_date > worked_on
  end

  def finished_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が必要です") if started_at.blank? && finished_at.present?
  end

  def started_at_must_be_before_finished_at
    return if started_at.blank? || finished_at.blank?

    errors.add(:started_at, "より早い退勤時間は無効です") if started_at > finished_at
  end
end