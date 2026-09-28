class MonthlyApproval < ApplicationRecord
  include ApproverValidatable
  include StatusPresentable

  belongs_to :user
  belongs_to :approver, class_name: "User"

  validates :month, presence: true
  validates :user_id, uniqueness: { scope: :month }
  validate :month_must_be_the_first_day_of_month

  private

    def month_must_be_the_first_day_of_month
      return if month.blank?

      errors.add(:month, "は月初の日付にしてください") unless month == month.beginning_of_month
    end
end
