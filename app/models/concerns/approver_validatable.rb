module ApproverValidatable
  extend ActiveSupport::Concern

  included do
    validate :approver_must_be_another_supervisor
  end

  private

    def approver_must_be_another_supervisor
      return if approver.nil?

      errors.add(:approver, "は上長を指定してください") unless approver.supervisor?
      errors.add(:approver_id, "には自分自身を指定できません") if approver_id.present? && approver_id == user_id
    end
end
