require "rails_helper"

RSpec.describe "権限制御", type: :request do
  let(:admin)      { create(:user, admin: true) }
  let(:general)    { create(:user) }
  let(:supervisor) { create(:user, supervisor: true) }
  let!(:office)    { create(:office) }

  def log_in_as(user)
    post login_path, params: { session: { email: user.email, password: user.password } }
  end

  shared_examples "管理ユーザのページに遷移・変更できない" do
    it "管理ユーザのページを表示できない" do
      [users_path, working_users_path, offices_path, new_office_path,
       edit_office_path(office), edit_system_setting_path].each do |path|
        get path
        expect(response).to redirect_to(root_url), "#{path} に遷移できてしまう"
      end
    end

    it "管理ユーザの操作で変更できない" do
      target = create(:user)
      expect { delete user_path(target) }.not_to change(User, :count)
      expect { post offices_path, params: { office: { name: "新拠点", attendance_type: "出勤" } } }.not_to change(Office, :count)
      expect { delete office_path(office) }.not_to change(Office, :count)

      patch office_path(office), params: { office: { name: "変更後" } }
      expect(office.reload.name).not_to eq "変更後"

      patch update_basic_info_user_path(target), params: { user: { name: "変更後" } },
                                                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(target.reload.name).not_to eq "変更後"
    end
  end

  context "一般ユーザの場合" do
    before { log_in_as(general) }

    it_behaves_like "管理ユーザのページに遷移・変更できない"
  end

  context "上長ユーザの場合" do
    before { log_in_as(supervisor) }

    it_behaves_like "管理ユーザのページに遷移・変更できない"
  end

  context "管理ユーザの場合" do
    before { log_in_as(admin) }

    it "ログインするとユーザ一覧に移る" do
      expect(response).to redirect_to(users_url)
    end

    it "自身の勤怠画面とCSVを表示できない" do
      get user_path(admin)
      expect(response).to redirect_to(users_url)
      expect(flash[:danger]).to eq "管理者は勤怠画面を利用できません。"

      get user_path(admin, format: :csv)
      expect(response).to redirect_to(users_url)
    end

    it "ほかのユーザの勤怠画面も表示できない" do
      get user_path(general)
      expect(response).to redirect_to(users_url)
    end

    it "勤怠の編集画面を表示できず、更新もできない" do
      get attendances_edit_one_month_user_path(admin)
      expect(response).to redirect_to(users_url)

      attendance = create(:attendance, user: general)
      patch attendances_update_one_month_user_path(general), params: {
        user: { attendances: { attendance.id.to_s => { started_at_hour: "9", started_at_minute: "0",
                                                       finished_at_hour: "18", finished_at_minute: "0" } } }
      }
      expect(response).to redirect_to(users_url)
      expect(attendance.reload.started_at).to be_nil
    end

    it "勤怠修正ログを表示できない" do
      get attendances_correction_logs_user_path(admin), headers: { "Turbo-Frame" => "modal" }
      expect(response).to redirect_to(users_url)
    end

    it "残業申請・所属長承認の申請ができない" do
      get new_user_overtime_request_path(admin)
      expect(response).to redirect_to(users_url)

      expect {
        post user_monthly_approvals_path(admin),
             params: { monthly_approval: { month: Date.current.beginning_of_month, approver_id: supervisor.id } }
      }.not_to change(MonthlyApproval, :count)
    end

    it "自分の設定を保存すると、勤怠画面ではなくユーザ一覧に戻る" do
      patch user_path(admin), params: { user: { name: "管理者の新しい名前", email: admin.email,
                                                password: "", password_confirmation: "" } }
      expect(response).to redirect_to(users_url)
      expect(flash[:success]).to eq "ユーザー情報を更新しました。"
      expect(admin.reload.name).to eq "管理者の新しい名前"
    end
  end
end
