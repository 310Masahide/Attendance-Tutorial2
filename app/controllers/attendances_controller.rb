class AttendancesController < ApplicationController
  include AdminOrCorrectUserScoped

  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:edit_one_month, :update_one_month]
  before_action :admin_or_correct_user, only: [:edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  before_action :set_approvers, only: :edit_one_month

  def edit_one_month
  end

  def update_one_month
    if current_user.admin?
      update_attendances_directly
      flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    else
      applied_count, withdrawn_count, dates_without_approver, invalid_dates = request_attendance_corrections
      messages = []

      if dates_without_approver.any?
        dates = dates_without_approver.map { |date| I18n.l(date, format: :short) }.join("、")
        messages << "#{dates} は指示者確認印(承認者)が未選択のため、申請できませんでした。承認者を選択してください。"
      end

      if invalid_dates.any?
        dates = invalid_dates.map { |date| I18n.l(date, format: :short) }.join("、")
        messages << "#{dates} は入力内容が無効なため、申請できませんでした。"
      end

      success_messages = []
      success_messages << "#{applied_count}件の勤怠変更を申請しました。" if applied_count.positive?
      success_messages << "#{withdrawn_count}件の勤怠変更申請を取り下げました。" if withdrawn_count.positive?
      flash[:success] = success_messages.join if success_messages.any?
      flash[:danger]  = messages.join if messages.any?
      flash[:info]    = "変更内容がありませんでした。" if flash.empty?
    end

    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid, ArgumentError
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  rescue ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked
    flash[:danger] = "他の操作と競合したため、更新できませんでした。もう一度お試しください。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end

  private

  def update_attendances_directly
    attendances = @user.attendances.includes(:correction_requests).where(id: attendances_params.keys).index_by { |attendance| attendance.id.to_s }

    ActiveRecord::Base.transaction do
      attendances_params.each do |id, item|
        attendance = attendances[id]
        next unless attendance

        attendance.update!(build_attendance_attributes(attendance, item))
        next unless attendance.saved_changes.except("updated_at").any?

        # 管理者が直接内容を確定させたので、その日の保留中の申請は無効(却下)にする
        # (.includesでまとめ取得済みのデータを使うため、awaiting_decisionスコープ(where)ではなくメモリ内でフィルタする)
        attendance.correction_requests.select(&:pending?).each { |request| request.update!(status: :rejected) }
      end
    end
  end

    # 一般ユーザーが勤怠変更を申請する経路
    def request_attendance_corrections
      applied_count = 0
      withdrawn_count = 0
      dates_without_approver = []
      invalid_dates = []
      attendances = @user.attendances.includes(:correction_requests)
                          .where(id: attendances_params.keys)
                          .index_by { |attendance| attendance.id.to_s }

      attendances_params.each do |id, item|
        attendance = attendances[id]
        next unless attendance

        attendance_attributes = build_attendance_attributes(attendance, item)
        next unless attendance_changed?(attendance, attendance_attributes)

        # 取り下げ(実績に戻す)だけなら承認者は不要
        if item[:approver_id].blank? && !same_as_actual?(attendance, attendance_attributes)
          dates_without_approver << attendance.worked_on
          next
        end

        ActiveRecord::Base.transaction do
          # ここまではまとめ取得した(古いかもしれない)データでの判定なので、
          # 申請を作る直前に最新状態へロックし直し、変更の有無を確定させる
          attendance.lock!
          attendance.correction_requests.reload
          next unless attendance_changed?(attendance, attendance_attributes)

          # 実績と同じ値に戻された場合は、申請中の内容を取り下げる(なし=未処理に数えない)
          if same_as_actual?(attendance, attendance_attributes)
            attendance.correction_requests.detect(&:pending?)&.update!(status: :unset)
            withdrawn_count += 1
            next
          end

          request = attendance.correction_requests.detect(&:pending?) || attendance.correction_requests.build
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
      rescue ActiveRecord::RecordInvalid, ArgumentError
        invalid_dates << attendance.worked_on
      end

      [applied_count, withdrawn_count, dates_without_approver, invalid_dates] 
    end

    def attendance_changed?(attendance, attendance_attributes)
      existing_request = attendance.correction_requests.detect(&:pending?)

      if existing_request
        baseline_started_at  = existing_request.requested_started_at
        baseline_finished_at = existing_request.requested_finished_at
        baseline_note        = existing_request.note
      else
        baseline_started_at  = attendance.started_at
        baseline_finished_at = attendance.finished_at
        baseline_note        = attendance.note
      end

      attendance_attributes[:started_at] != baseline_started_at ||
        attendance_attributes[:finished_at] != baseline_finished_at ||
        attendance_attributes[:note].to_s != baseline_note.to_s
    end

    # 入力が実績(Attendance)と同じ = 申請中の内容を取り下げて元に戻したい
    def same_as_actual?(attendance, attendance_attributes)
      attendance_attributes[:started_at] == attendance.started_at &&
        attendance_attributes[:finished_at] == attendance.finished_at &&
        attendance_attributes[:note].to_s == attendance.note.to_s
    end

    def attendances_params
      params.require(:user).permit(attendances: [
        :started_at_hour, :started_at_minute,
        :finished_at_hour, :finished_at_minute,
        :finishes_next_day, :note, :approver_id
      ])[:attendances] || {}
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
end
