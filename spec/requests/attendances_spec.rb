require "rails_helper"

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

  describe "GET correction_logs" do
    let(:user) { create(:user) }

    before do
      post login_path, params: { session: { email: user.email, password: user.password } }
    end

    it "モーダル(turbo-frame)として開くと、勤怠修正ログを表示する" do
      get attendances_correction_logs_user_path(user), headers: { "Turbo-Frame" => "modal" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include "勤怠ログ"
    end

    it "他人の勤怠修正ログは見られない" do
      other = create(:user)
      get attendances_correction_logs_user_path(other), headers: { "Turbo-Frame" => "modal" }
      expect(response).to redirect_to(root_url)
    end

    context "年・月で絞り込む場合" do
      before do
        approver = create(:user, supervisor: true)
        # 承認日が勤怠の日付と重ならないよう、承認する日時を固定します
        travel_to Time.zone.local(2027, 1, 15, 10, 0) do
          [Date.new(2025, 9, 1), Date.new(2026, 9, 1), Date.new(2026, 10, 1)].each do |date|
            attendance = create(:attendance, user: user, worked_on: date,
                                             started_at: date.in_time_zone.change(hour: 9),
                                             finished_at: date.in_time_zone.change(hour: 18))
            create(:attendance_correction_request, attendance: attendance, approver: approver,
                                                   requested_started_at: date.in_time_zone.change(hour: 10),
                                                   requested_finished_at: date.in_time_zone.change(hour: 19)).update!(status: :approved)
          end
        end
      end

      it "年だけを選ぶと、その年のログだけを表示する" do
        get attendances_correction_logs_user_path(user, year: 2026), headers: { "Turbo-Frame" => "modal" }
        expect(response.body).to include("2026/09/01", "2026/10/01")
        expect(response.body).not_to include("2025/09/01")
      end

      it "月だけを選ぶと、その月のログだけを表示する" do
        get attendances_correction_logs_user_path(user, month: 9), headers: { "Turbo-Frame" => "modal" }
        expect(response.body).to include("2025/09/01", "2026/09/01")
        expect(response.body).not_to include("2026/10/01")
      end

      it "年と月の両方を選ぶと、その年月のログだけを表示する" do
        get attendances_correction_logs_user_path(user, year: 2026, month: 9), headers: { "Turbo-Frame" => "modal" }
        expect(response.body).to include("2026/09/01")
        expect(response.body).not_to include("2025/09/01", "2026/10/01")
      end
    end

    context "上長ユーザーの場合" do
      let(:user) { create(:user, supervisor: true) }

      it "自分の勤怠修正ログを表示できる" do
        get attendances_correction_logs_user_path(user), headers: { "Turbo-Frame" => "modal" }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
