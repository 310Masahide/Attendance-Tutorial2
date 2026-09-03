class OvertimeRequestsController < ApplicationController
  before_action :logged_in_user
  before_action :set_user
  before_action :admin_or_correct_user

  def new
    @overtime_request = @user.overtime_requests.new(worked_on: params[:worked_on])
    @approvers = User.supervisors.where.not(id: @user.id)
  end

  def create
    @overtime_request = @user.overtime_requests.new(overtime_request_params)
    @approvers = User.supervisors.where.not(id: @user.id)
    if @overtime_request.save
      flash.now[:success] = "残業申請を送信しました。"
    else
      flash.now[:danger] = "残業申請の送信に失敗しました。"
    end
    # create.turbo_stream.erb で分岐して描画する
  end

  def edit
    @overtime_request = @user.overtime_requests.find(params[:id])
    unless @overtime_request.editable?
      flash[:danger] = "この申請は編集できません。"
      redirect_to(@user) and return
    end
    @approvers = User.supervisors.where.not(id: @user.id)
  end

  def update
    @overtime_request = @user.overtime_requests.find(params[:id])
    @approvers = User.supervisors.where.not(id: @user.id)

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
    @overtime_request = @user.overtime_requests.find(params[:id])

    if @overtime_request.pending? && @overtime_request.destroy
      flash.now[:success] = "残業申請を取り消しました。"
    else
      flash.now[:danger] = "この申請は取り消せません。"
    end
    # destroy.turbo_stream.erb で分岐して描画する
  end

  def results
    @unconfirmed_results = @user.overtime_requests.unconfirmed_results.includes(:approver).to_a
    mark_results_as_confirmed(@unconfirmed_results)
  end

  private

    def mark_results_as_confirmed(overtime_requests)
      return unless current_user?(@user)
      return if overtime_requests.empty?

      OvertimeRequest.where(id: overtime_requests.map(&:id))
                     .update_all(applicant_confirmed: true)
    end

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
end
