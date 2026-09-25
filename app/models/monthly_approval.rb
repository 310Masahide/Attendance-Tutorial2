class MonthlyApproval < ApplicationRecord
  belongs_to :user
  belongs_to :approver, class_name: "User"

  enum status: { unset: 0, pending: 1, approved: 2, rejected: 3 }

  scope :awaiting_decision, -> { where(status: [:pending, :unset]) }

  validates :month, presence: true
  validates :user_id, uniqueness: { scope: :month }
  validate :approver_must_be_another_supervisor
  validate :month_must_be_the_first_day_of_month

  def status_label
    I18n.t("activerecord.attributes.monthly_approval.statuses.#{status}")
  end

  def decided?
    approved? || rejected?
  end

  def self.status_options
    [["なし", "unset"], ["申請中", "pending"], ["承認", "approved"], ["否認", "rejected"]]
  end

  private

    def approver_must_be_another_supervisor
      return if approver.nil?

      errors.add(:approver, "は上長を指定してください") unless approver.supervisor?
      errors.add(:approver_id, "には自分自身を指定できません") if approver_id.present? && approver_id == user_id
    end

    def month_must_be_the_first_day_of_month
      return if month.blank?

      errors.add(:month, "は月初の日付にしてください") unless month == month.beginning_of_month
    end
end
