require "rails_helper"

RSpec.describe "Offices", type: :request do
  let(:admin) { create(:user, admin: true) }
  let!(:office) { create(:office, office_number: 1, name: "本社", office_type: "出勤") }

  context "管理者の場合" do
    before do
      post login_path, params: { session: { email: admin.email, password: admin.password } }
    end

    it "拠点情報の一覧を表示できる" do
      get offices_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include "本社"
    end

    it "拠点情報を追加できる" do
      expect {
        post offices_path, params: { office: { office_number: 2, name: "大阪支社", office_type: "退勤" } }
      }.to change(Office, :count).by(1)
      expect(response).to redirect_to(offices_url)
    end

    it "入力に誤りがあると追加できず、追加画面を表示する" do
      expect {
        post offices_path, params: { office: { office_number: 1, name: "", office_type: "出勤" } }
      }.not_to change(Office, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "拠点情報を編集できる" do
      patch office_path(office), params: { office: { name: "東京本社" } }
      expect(office.reload.name).to eq "東京本社"
      expect(response).to redirect_to(offices_url)
    end

    it "拠点情報を削除できる" do
      expect { delete office_path(office) }.to change(Office, :count).by(-1)
      expect(response).to redirect_to(offices_url)
    end
  end

  context "管理者以外の場合" do
    let(:user) { create(:user) }

    before do
      post login_path, params: { session: { email: user.email, password: user.password } }
    end

    it "拠点情報の一覧を見られない" do
      get offices_path
      expect(response).to redirect_to(root_url)
    end

    it "拠点情報を追加できない" do
      expect {
        post offices_path, params: { office: { office_number: 2, name: "大阪支社", office_type: "退勤" } }
      }.not_to change(Office, :count)
    end

    it "拠点情報を削除できない" do
      expect { delete office_path(office) }.not_to change(Office, :count)
    end
  end

  context "ログインしていない場合" do
    it "ログイン画面に移る" do
      get offices_path
      expect(response).to redirect_to(login_url)
    end
  end
end
