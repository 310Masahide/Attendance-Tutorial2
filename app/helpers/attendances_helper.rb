module AttendancesHelper

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
