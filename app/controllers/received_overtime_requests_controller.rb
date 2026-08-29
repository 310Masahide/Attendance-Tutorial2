class ReceivedOvertimeRequestsController < ApplicationController
  before_action :set_user
  before_action :logged_in_user
  before_action :correct_supervisor

  def index
    redirect_to(@user) and return unless turbo_frame_request?

    @requests_by_applicant = @user.received_overtime_requests
                                   .where(status: [:pending, :unset])
                                   .includes(:user)
                                   .order(:worked_on)
                                   .group_by(&:user)
  end

  def bulk_update
    updated_ids = []
    params[:overtime_requests]&.each do |id, attrs|
      next unless attrs[:apply] == "1" # 「変更」チェックが無い行はスキップ
      request = @user.received_overtime_requests.find(id) # scopeで他人の申請を弄れないようにする
      request.update(status: attrs[:status])
      updated_ids << request.id if %w[approved rejected].include?(attrs[:status])
  end
  @results = OvertimeRequest.where(id: updated_ids)
  @requests_by_applicant = @user.received_overtime_requests.where(status: [:pending, :unset]).includes(:user).order(:worked_on).group_by(&:user)
end

  private

    def set_user
      @user = User.find(params[:id])
    end

    def correct_supervisor
      redirect_to(root_url) unless current_user?(@user) && current_user.supervisor?
    end
end
