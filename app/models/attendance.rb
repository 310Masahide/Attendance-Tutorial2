class Attendance < ApplicationRecord
  belongs_to :user
  has_many :correction_requests, -> { order(created_at: :desc) },
           class_name: "AttendanceCorrectionRequest", dependent: :destroy
  has_one  :latest_correction_request, -> { order(created_at: :desc) },
           class_name: "AttendanceCorrectionRequest"

  NOTE_MAX_LENGTH = 50
  
  validates :worked_on, presence: true
  validates :note, length: { maximum: NOTE_MAX_LENGTH }

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