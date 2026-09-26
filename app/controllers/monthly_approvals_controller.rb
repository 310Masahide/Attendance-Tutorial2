class MonthlyApprovalsController < ApplicationController
  include AdminOrCorrectUserScoped

  before_action :logged_in_user
  before_action :set_user
  before_action :admin_or_correct_user
  before_action :set_monthly_approval, only: :update

  def create
    @monthly_approval = @user.monthly_approvals.new(monthly_approval_params.merge(status: :pending))
    if @monthly_approval.save
      flash[:success] = "所属長へ月次承認を申請しました。"
    else
      flash[:danger] = "月次承認の申請に失敗しました。"
    end
    redirect_to user_url(@user, date: monthly_approval_params[:month])
  rescue ActiveRecord::RecordNotUnique
    flash[:danger] = "既に同じ月の申請が存在します。画面を更新してからやり直してください。"
    redirect_to user_url(@user, date: monthly_approval_params[:month])
  end

  def update
    if @monthly_approval.update(monthly_approval_params.merge(status: :pending))
      flash[:success] = "所属長へ月次承認を再申請しました。"
    else
      flash[:danger] = "月次承認の再申請に失敗しました。"
    end
    redirect_to user_url(@user, date: monthly_approval_params[:month])
  rescue ActiveRecord::RecordNotUnique
    flash[:danger] = "既に同じ月の申請が存在します。画面を更新してからやり直してください。"
    redirect_to user_url(@user, date: monthly_approval_params[:month])
  end

  private

    def set_user
      @user = User.find(params[:user_id])
    end

    def monthly_approval_params
      params.require(:monthly_approval).permit(:month, :approver_id)
    end

    def set_monthly_approval
      @monthly_approval = @user.monthly_approvals.find(params[:id])
    end
end
