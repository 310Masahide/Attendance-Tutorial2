class OvertimeRequestsController < ApplicationController
  before_action :set_user
  before_action :logged_in_user
  before_action :admin_or_correct_user

  def index
    @overtime_requests = @user.overtime_requests
  end

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

  def results
    @results = @user.overtime_requests.unconfirmed_results.to_a
    @user.overtime_requests.unconfirmed_results.update_all(applicant_confirmed: true)
  end

  private

    def set_user
      @user = User.find(params[:id]) # member内ネストのため :user_id ではなく :id
    end

    def admin_or_correct_user
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "権限がありません。"
        redirect_to(root_url)
      end
    end

    def overtime_request_params
      params.require(:overtime_request).permit(:worked_on, :finished_hour, :finished_minute, :next_day, :content, :approver_id)
    end
end
