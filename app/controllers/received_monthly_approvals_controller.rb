class ReceivedMonthlyApprovalsController < ApplicationController
  before_action :logged_in_user
  before_action :set_supervisor
  before_action :correct_supervisor

  # 上長が一括で切り替えられるステータス
  SELECTABLE_STATUSES = %w[unset pending approved rejected].freeze

  def index
    return redirect_to(@supervisor) unless turbo_frame_request?

    @approvals_by_applicant = pending_approvals_by_applicant
    @modal_title = modal_title_for(@approvals_by_applicant)
  end

  def bulk_update
    apply_status_changes(submitted_changes)
    @approvals_by_applicant = pending_approvals_by_applicant
    @modal_title = modal_title_for(@approvals_by_applicant)
  end

  private

    def modal_title_for(approvals_by_applicant)
      return "【所属長承認申請のお知らせ】" if approvals_by_applicant.blank?

      "【#{approvals_by_applicant.keys.map(&:name).join('、')}からの1ヶ月分勤怠申請】"
    end


    # 「変更」にチェックが入っていて、かつ選択肢に無いステータスを弾いた行だけを返す
    def submitted_changes
      submitted = params[:monthly_approvals] || {}

      submitted.to_unsafe_h.select do |_id, attributes|
        attributes["apply"] == "1" && SELECTABLE_STATUSES.include?(attributes["status"])
      end
    end

    def apply_status_changes(changes)
      # 自分宛ての申請だけを対象にすることで、他人の申請を書き換えられないようにする
      target_approvals = @supervisor.received_monthly_approvals.where(id: changes.keys)

      MonthlyApproval.transaction do
        target_approvals.each do |approval|
          approval.update!(status: changes[approval.id.to_s]["status"])
        end
      end
    end

    def pending_approvals_by_applicant
      @supervisor.received_monthly_approvals
                 .where(status: %i[pending unset])
                 .includes(:user)
                 .order(:month)
                 .group_by(&:user)
    end

    def set_supervisor
      @supervisor = User.find(params[:id])
    end

    def correct_supervisor
      return if current_user?(@supervisor) && current_user.supervisor?

      flash[:danger] = "権限がありません。"
      redirect_to(root_url)
    end
end

