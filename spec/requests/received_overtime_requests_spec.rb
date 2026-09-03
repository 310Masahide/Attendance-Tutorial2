require 'rails_helper'

RSpec.describe "ReceivedOvertimeRequests", type: :request do
  let(:applicant)     { create(:user) }
  let(:supervisor_a)  { create(:user, supervisor: true) }
  let(:supervisor_b)  { create(:user, supervisor: true) }

  def login_as(user)
    post login_path, params: { session: { email: user.email, password: user.password } }
  end

  describe 'PATCH bulk_update' do
    it '他人宛ての申請は一括更新で書き換えられない' do
      overtime_request = create(:overtime_request, user: applicant, approver: supervisor_b, status: :pending)
      login_as(supervisor_a)

      patch bulk_update_received_overtime_requests_user_path(supervisor_a),
            params: { overtime_requests: { overtime_request.id.to_s => { status: 'approved', apply: '1' } } }

      overtime_request.reload
      expect(overtime_request).to be_pending
    end

    it '選択肢にないステータスを送っても500にならない' do
      overtime_request = create(:overtime_request, user: applicant, approver: supervisor_a, status: :pending)
      login_as(supervisor_a)

      patch bulk_update_received_overtime_requests_user_path(supervisor_a),
            params: { overtime_requests: { overtime_request.id.to_s => { status: 'foo', apply: '1' } } }

      expect(response).not_to have_http_status(:internal_server_error)
      overtime_request.reload
      expect(overtime_request).to be_pending
    end
  end
end
