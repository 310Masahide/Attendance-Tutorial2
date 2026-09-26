require 'rails_helper'

RSpec.describe "Attendances", type: :request do
  describe "PATCH /users/:user_id/attendances/update_one_month" do
    it "存在しないattendance idが含まれていてもエラーにならず、正常に処理される" do
      user = create(:user)
      approver = create(:user, supervisor: true)
      attendance = create(:attendance, user: user)
      post login_path, params: { session: { email: user.email, password: user.password } }

      nonexistent_id = Attendance.maximum(:id).to_i + 1

      patch attendances_update_one_month_user_path(user, date: attendance.worked_on.beginning_of_month), params: {
        user: {
          attendances: {
            nonexistent_id.to_s => {
              started_at_hour: "9", started_at_minute: "0",
              finished_at_hour: "18", finished_at_minute: "0",
              finishes_next_day: "0", note: "", approver_id: approver.id.to_s
            }
          }
        }
      }

      expect(response).to be_redirect
      expect(response.location).to include("/users/#{user.id}")
    end
  end
end
