class OvertimeRequestsController < ApplicationController
  before_action :logged_in_user
  before_action :set_user
  before_action :admin_or_correct_user
  before_action :set_overtime_request, only: %i[edit update destroy]
  before_action :set_approvers,        only: %i[new create edit update]

  def new
    @overtime_request = @user.overtime_requests.new(worked_on: params[:worked_on])
  end

  def create
    @overtime_request = @user.overtime_requests.new(overtime_request_params)
    if @overtime_request.save
      flash.now[:success] = "残業申請を送信しました。"
    else
      flash.now[:danger] = "残業申請の送信に失敗しました。"
    end
    # create.turbo_stream.erb で分岐して描画する
  end

  def edit
    unless @overtime_request.editable?
      flash[:danger] = "この申請は編集できません。"
      redirect_to(@user) and return
    end
  end

  def update
    unless @overtime_request.editable?
      flash.now[:danger] = "この申請は編集できません。"
      return
    end

    # 再申請の意味も兼ねるため、保存できたら必ず「申請中」に戻す
    if @overtime_request.update(overtime_request_params.merge(status: :pending, applicant_confirmed: false))
      flash.now[:success] = "残業申請を更新しました。"
    else
      flash.now[:danger] = "残業申請の更新に失敗しました。"
    end
    # update.turbo_stream.erb で分岐して描画する
  end

  def destroy
    if @overtime_request.pending? && @overtime_request.destroy
      flash.now[:success] = "残業申請を取り消しました。"
    else
      flash.now[:danger] = "この申請は取り消せません。"
    end
    # destroy.turbo_stream.erb で分岐して描画する
  end

  private

    def set_user
      @user = User.find(params[:user_id])
    end

    def admin_or_correct_user
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "権限がありません。"
        redirect_to(root_url)
      end
    end

    def overtime_request_params
      params.require(:overtime_request).permit(:worked_on, :finished_hour, :finished_minute, :finishes_next_day, :content, :approver_id)
    end

    def set_overtime_request
      @overtime_request = @user.overtime_requests.find(params[:id])
    end

    def set_approvers
      @approvers = @user.approver_candidates
    end
end
