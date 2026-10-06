class Office < ApplicationRecord
  OFFICE_TYPES = %w[出勤 退勤].freeze

  validates :office_number, presence: true, uniqueness: true,
                            numericality: { only_integer: true, greater_than: 0 }
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :office_type, presence: true, inclusion: { in: OFFICE_TYPES }
end
