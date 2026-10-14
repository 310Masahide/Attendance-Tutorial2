class Office < ApplicationRecord
  ATTENDANCE_TYPES = %w[出勤 退勤].freeze

  before_validation :assign_office_number, on: :create

  validates :office_number, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :attendance_type, presence: true, inclusion: { in: ATTENDANCE_TYPES, allow_blank: true }

  private

    # 拠点番号は自動採番します(登録済みの一番大きい番号＋1)
    def assign_office_number
      self.office_number ||= (Office.maximum(:office_number) || 0) + 1
    end
end
