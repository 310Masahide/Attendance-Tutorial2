module MonthlyApprovalsHelper
  def monthly_approval_notices_for(user)
    return [] unless user.supervisor?

    [{ label: "【所属長承認申請のお知らせ】", path: received_monthly_approvals_user_path(user),
       count: user.received_monthly_approvals.awaiting_decision.count }]
  end
end
