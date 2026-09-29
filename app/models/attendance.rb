require "csv"

class Attendance < ApplicationRecord
  belongs_to :user
  has_many :correction_requests, -> { order(created_at: :desc) },
           class_name: "AttendanceCorrectionRequest", dependent: :destroy
  has_one  :latest_correction_request, -> { order(created_at: :desc) },
           class_name: "AttendanceCorrectionRequest"

  NOTE_MAX_LENGTH = 50

  CSV_HEADERS = %w[日付 曜日 出社時間 退社時間 備考].freeze

  # 勤怠(承認済みの実績)をCSVにします。
  # 勤怠変更の申請中(未承認)の値はAttendanceに反映されていないため含まれません。
  def self.to_csv
    bom = "\uFEFF" # Excelで開いたときに文字化けしないように付けます
    bom + CSV.generate do |csv|
      csv << CSV_HEADERS
      includes(:correction_requests).each do |attendance|
        # 編集承認依頼中(未承認)の日は出力しない
        next if attendance.correction_requests.any?(&:pending?)

        csv << [
          I18n.l(attendance.worked_on, format: "%Y/%m/%d"),
          I18n.l(attendance.worked_on, format: "%a"),
          attendance.started_at&.strftime("%H:%M"),
          attendance.finished_at_for_csv,
          csv_safe(attendance.note.presence)
        ]
      end
    end
  end

  # 退社が翌日の場合は「翌」を付けます(例: 翌02:00)
  def finished_at_for_csv
    return if finished_at.nil?

    "#{'翌' if finished_at.to_date > worked_on}#{finished_at.strftime('%H:%M')}"
  end

  # Excelで数式として実行されないよう、= + - @ などで始まる値の先頭に ' を付けます(CSVインジェクション対策)
  def self.csv_safe(value)
    value.to_s.match?(/\A[=+\-@\t\r]/) ? "'#{value}" : value
  end
  private_class_method :csv_safe

  validates :worked_on, presence: true
  validates :note, length: { maximum: NOTE_MAX_LENGTH }

  validate :finished_at_is_invalid_without_a_started_at
  validate :started_at_must_be_before_finished_at

  def finished_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が必要です") if started_at.blank? && finished_at.present?
  end

  def started_at_must_be_before_finished_at
    return if started_at.blank? || finished_at.blank?

    errors.add(:started_at, "より早い退勤時間は無効です") if started_at > finished_at
  end
end