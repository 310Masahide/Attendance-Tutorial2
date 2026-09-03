module OvertimeRequestsHelper
  def hour_options
    (0..23).map { |hour| [format("%02d", hour), hour] }
  end

  def minute_options
    (0..59).map { |minute| [format("%02d", minute), minute] }
  end

  def overtime_notices_for(user)
    notices = []

    if user.supervisor?
      notices << { label: "【残業申請のお知らせ】", path: received_overtime_requests_user_path(user),
                    count: user.received_overtime_requests.pending.count }
    end

    unless user.admin?
      notices << { label: "【残業申請の結果】", path: results_user_overtime_requests_path(user),
                    count: user.overtime_requests.unconfirmed_results.count }
    end

    notices
  end
end