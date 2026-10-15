require "rails_helper"

RSpec.describe "SystemSettings", type: :request do
  it "管理者は基本情報の修正ページを開ける" do
    admin = create(:user, admin: true)
    post login_path, params: { session: { email: admin.email, password: admin.password } }
    get edit_system_setting_path
    expect(response).to have_http_status(:ok)
  end

  it "管理者以外は基本情報の修正ページを開けない" do
    user = create(:user)
    post login_path, params: { session: { email: user.email, password: user.password } }
    get edit_system_setting_path
    expect(response).to redirect_to(root_url)
  end
end
