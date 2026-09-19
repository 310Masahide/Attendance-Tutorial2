class ReceivedOvertimeRequestsController < ApplicationController
  before_action :logged_in_user
  before_action :set_supervisor
  before_action :correct_supervisor

  # 上長が一括で切り替えられるステータス
  SELECTABLE_STATUSES = %w[unset pending approved rejected].freeze

  def index
    return redirect_to(@supervisor) unless turbo_frame_request?

    @requests_by_applicant = pending_requests_by_applicant
  end

  def bulk_update
    apply_status_changes(submitted_changes)
    @requests_by_applicant = pending_requests_by_applicant
  end

  private

  # 「変更」にチェックが入っていて、かつ選択肢に無いステータスを弾いた行だけを返す
  def submitted_changes
    submitted = params[:overtime_requests] || {}

    submitted.to_unsafe_h.select do |_id, attributes|
      attributes["apply"] == "1" && SELECTABLE_STATUSES.include?(attributes["status"])
    end
  end

  def apply_status_changes(changes)
    # 自分宛ての申請だけを対象にすることで、他人の申請を書き換えられないようにする
    target_requests = @supervisor.received_overtime_requests.where(id: changes.keys)

    OvertimeRequest.transaction do
      target_requests.each do |overtime_request|
        overtime_request.update!(status: changes[overtime_request.id.to_s]["status"])
      end
    end
  end

  def pending_requests_by_applicant
    @supervisor.received_overtime_requests
               .where(status: %i[pending unset])
               .includes(:user)
               .order(:worked_on)
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
