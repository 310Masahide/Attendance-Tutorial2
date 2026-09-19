class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month, :update_one_month]
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
    if current_user.admin?
      update_attendances_directly
      flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    else
      applied_count, dates_without_approver = request_attendance_corrections

      if dates_without_approver.any?
        dates = dates_without_approver.map { |date| I18n.l(date, format: :short) }.join("、")
        message = "#{dates} は指示者確認印(承認者)が未選択のため、申請できませんでした。承認者を選択してください。"
        if applied_count.positive?
          flash[:success] = "#{applied_count}件の勤怠変更を申請しました。#{message}"
        else
          flash[:danger] = message
        end
      elsif applied_count.positive?
        flash[:success] = "#{applied_count}件の勤怠変更を申請しました。"
      else
        flash[:info] = "変更内容がありませんでした。"
      end
    end

    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end

  private

    def update_attendances_directly
      ActiveRecord::Base.transaction do
        attendances_params.each do |id, item|
          attendance = @user.attendances.find(id)
          attendance.update!(build_attendance_attributes(attendance, item))
        end
      end
    end

    # 一般ユーザーが勤怠変更を申請する経路
    def request_attendance_corrections
      applied_count = 0
      dates_without_approver = []

      ActiveRecord::Base.transaction do
        attendances_params.each do |id, item|
          attendance = @user.attendances.find(id)
          attendance_attributes = build_attendance_attributes(attendance, item)
          has_changes = attendance_attributes[:started_at] != attendance.started_at ||
                        attendance_attributes[:finished_at] != attendance.finished_at ||
                        attendance_attributes[:note].to_s != attendance.note.to_s
          next unless has_changes

          if item[:approver_id].blank?
            dates_without_approver << attendance.worked_on
            next
          end

          request = attendance.correction_requests.awaiting_decision.first || attendance.correction_requests.build
          request.update!(
            user: @user,
            approver_id: item[:approver_id],
            requested_started_at:  attendance_attributes[:started_at],
            requested_finished_at: attendance_attributes[:finished_at],
            note: attendance_attributes[:note],
            status: :pending
          )
          applied_count += 1
        end
      end

      [applied_count, dates_without_approver]
    end

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