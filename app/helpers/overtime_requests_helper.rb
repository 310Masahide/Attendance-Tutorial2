module OvertimeRequestsHelper
  def overtime_notices_for(user)
    notices = []

    if user.supervisor?
      notices << { label: "【残業申請のお知らせ】", path: received_overtime_requests_user_path(user),
                    count: user.received_overtime_requests.awaiting_decision.count }
    end

    notices
  end
end