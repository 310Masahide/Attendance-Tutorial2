module AttendancesHelper

  # 勤怠修正ログの時刻表示。日をまたぐ場合は「翌」を付けます(例: 翌02:00)
  def correction_log_time(time, worked_on)
    return if time.nil?

    "#{'翌' if time.to_date > worked_on}#{time.strftime('%H:%M')}"
  end

  def working_times(start, finish)
    format("%.2f", (((finish - start) / 60) / 60.0))
  end

  def attendance_correction_notices_for(user)
    notices = []

    if user.supervisor?
      notices << {
        label: "【勤怠変更申請のお知らせ】",
        path: received_attendance_correction_requests_user_path(user),
        count: user.received_attendance_correction_requests.awaiting_decision.count
      }
    end

    notices
  end
end
