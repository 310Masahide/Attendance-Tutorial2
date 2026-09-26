class ReceivedMonthlyApprovalsController < ApplicationController
  before_action :logged_in_user
  include SupervisorScoped
  include BulkStatusUpdatable

  def index
    return redirect_to(@supervisor) unless turbo_frame_request?

    @approvals_by_applicant = pending_approvals_by_applicant
    @modal_title = modal_title_for(@approvals_by_applicant)
  end

  def bulk_update
    failed_count = apply_status_changes(@supervisor.received_monthly_approvals, submitted_changes(:monthly_approvals))
    flash.now[:danger] = "#{failed_count}件の更新に失敗しました。" if failed_count.positive?
    @approvals_by_applicant = pending_approvals_by_applicant
    @modal_title = modal_title_for(@approvals_by_applicant)
  end

  private

    def modal_title_for(approvals_by_applicant)
      return "【所属長承認申請のお知らせ】" if approvals_by_applicant.blank?

      "【#{approvals_by_applicant.keys.map(&:name).join('、')}からの1ヶ月分勤怠申請】"
    end

    def pending_approvals_by_applicant
      group_pending_by_applicant(@supervisor.received_monthly_approvals, includes: [:user], order: :month)
    end
end


