require "rails_helper"

RSpec.describe "Offices", type: :request do
  let(:admin) { create(:user, admin: true) }
  let!(:office) { create(:office, name: "本社", attendance_type: "出勤") }

  context "管理者の場合" do
    before do
      post login_path, params: { session: { email: admin.email, password: admin.password } }
    end

    it "拠点一覧を表示できる" do
      get offices_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("拠点一覧", "本社", "出勤", "拠点情報追加")
    end

    it "拠点を追加でき、拠点番号は自動で採番される" do
      expect {
        post offices_path, params: { office: { name: "大阪支社", attendance_type: "退勤" } }
      }.to change(Office, :count).by(1)
      expect(response).to redirect_to(offices_url)
      expect(flash[:success]).to eq "拠点登録完了しました"
      expect(Office.find_by(name: "大阪支社").office_number).to eq 2
    end

    it "拠点番号を送っても、自動採番の番号になる" do
      post offices_path, params: { office: { office_number: 99, name: "大阪支社", attendance_type: "退勤" } }
      expect(Office.find_by(name: "大阪支社").office_number).to eq 2
    end

    it "入力に誤りがあると追加できない" do
      expect {
        post offices_path, params: { office: { name: "", attendance_type: "" } }
      }.not_to change(Office, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "拠点情報を修正できる" do
      patch office_path(office), params: { office: { name: "東京本社", attendance_type: "退勤" } }
      expect(office.reload.name).to eq "東京本社"
      expect(office.attendance_type).to eq "退勤"
      expect(response).to redirect_to(offices_url)
    end

    it "拠点を削除できる" do
      expect { delete office_path(office) }.to change(Office, :count).by(-1)
      expect(response).to redirect_to(offices_url)
    end
  end

  context "管理者以外の場合" do
    let(:user) { create(:user) }

    before do
      post login_path, params: { session: { email: user.email, password: user.password } }
    end

    it "拠点一覧を見られない" do
      get offices_path
      expect(response).to redirect_to(root_url)
    end

    it "拠点を追加できない" do
      expect {
        post offices_path, params: { office: { name: "大阪支社", attendance_type: "退勤" } }
      }.not_to change(Office, :count)
    end

    it "拠点を削除できない" do
      expect { delete office_path(office) }.not_to change(Office, :count)
    end
  end
end
