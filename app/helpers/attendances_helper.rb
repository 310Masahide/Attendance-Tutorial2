module AttendancesHelper

  def attendance_state(attendance)
    # 受け取ったAttendanceオブジェクトが当日と一致するか評価します。
    if Date.current == attendance.worked_on
      return '出勤' if attendance.started_at.nil?
      return '退勤' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    # どれにも当てはまらなかった場合はfalseを返します。
    return false
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
        count: user.received_attendance_correction_requests.pending.count
      }
    end

    notices
  end
end
