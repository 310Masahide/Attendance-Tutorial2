class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  before_action :set_approvers, only: :edit_one_month

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end

  def edit_one_month
  end

  def update_one_month
    missing_approver_dates = []

    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = @user.attendances.find(id)

        if current_user.admin?
          attendance.update!(build_attendance_attributes(attendance, item))
        else
          attrs = build_attendance_attributes(attendance, item)
          changed = attrs[:started_at] != attendance.started_at ||
                    attrs[:finished_at] != attendance.finished_at ||
                    attrs[:note].to_s != attendance.note.to_s
          next unless changed

          if item[:approver_id].blank?
            missing_approver_dates << attendance.worked_on
            next
          end

          request = attendance.correction_request || attendance.build_correction_request
          request.update!(
            user: @user,
            approver_id: item[:approver_id],
            requested_started_at:  attrs[:started_at],
            requested_finished_at: attrs[:finished_at],
            note: attrs[:note],
            status: :pending
          )
        end
      end

      raise ActiveRecord::Rollback if missing_approver_dates.any?
    end

    if missing_approver_dates.any?
      dates = missing_approver_dates.map { |date| I18n.l(date, format: :short) }.join("、")
      flash[:danger] = "#{dates} は指示者確認印(承認者)が未選択のため、変更を申請できませんでした。承認者を選択してください。"
      redirect_to(attendances_edit_one_month_user_url(date: params[:date])) and return
    end

    flash[:success] = current_user.admin? ? "1ヶ月分の勤怠情報を更新しました。" : "勤怠変更を申請しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end

  private

    def attendances_params
      params.require(:user).permit(attendances: [
        :started_at_hour, :started_at_minute,
        :finished_at_hour, :finished_at_minute,
        :finishes_next_day, :note, :approver_id
      ])[:attendances]
    end

    def build_attendance_attributes(attendance, item)
    {
      started_at: build_time(attendance.worked_on, item[:started_at_hour], item[:started_at_minute]),
      finished_at: build_time(attendance.worked_on, item[:finished_at_hour], item[:finished_at_minute],
                               next_day: item[:finishes_next_day] == "1"),
      note: item[:note]
    }
  end

  def build_time(base_date, hour, minute, next_day: false)
    return nil if hour.blank? || minute.blank?

    date = next_day ? base_date + 1.day : base_date
    Time.zone.local(date.year, date.month, date.day, hour.to_i, minute.to_i)
  end

  def set_approvers
    @approvers = @user.approver_candidates
  end

    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
end