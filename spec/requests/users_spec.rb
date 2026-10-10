require 'rails_helper'


RSpec.describe "Users", type: :request do
  describe 'GET index' do
    let(:user) { create(:user, admin: true) }
  
      context 'ユーザーが5件存在する場合' do
        let!(:users) { create_list(:user, 4) }
  
        before do
          post login_path, params: { session: { email: user.email, password: user.password } }
          get users_path, as: :json
        end


      it "200 httpレスポンスを返す" do
        expect(response.status).to eq 200
      end


      it "自分を除いた4件を返す" do
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(4)
      end


      it "5件のユーザーを正確に返す" do
        json_response = JSON.parse(response.body)
        expected_users = users.map do |user|
          {
            'id' => user.id,
            'name' => user.name,
            'email' => user.email,
            'created_at' => user.created_at.as_json,
            'updated_at' => user.updated_at.as_json,
            'password_digest' => user.password_digest,
            'remember_digest' => user.remember_digest,
            'admin' => user.admin,
            'supervisor' => user.supervisor,
            'department' => user.department,
            'basic_time' => user.basic_time.as_json,
            'work_time' => user.work_time.as_json,
            'designated_work_start_time' => user.designated_work_start_time.as_json,
            'designated_work_end_time' => user.designated_work_end_time.as_json,
            'employee_number' => user.employee_number,
            'uid' => user.uid
          }
        end
        expect(json_response).to match_array(expected_users)
      end


      # ページネーションのテスト
      context 'ページネーションを含む場合' do
        let!(:users) { create_list(:user, 34) + [user] }
  
        it '1ページ目に30件のユーザを返す' do
          get users_path, params: { page: 1 }, as: :json
          json_response = JSON.parse(response.body)
          expect(json_response.length).to eq(30)
        end
  
        it '2ページ目に4件のユーザーを返す' do
          get users_path, params: { page: 2 }, as: :json
          json_response = JSON.parse(response.body)
          expect(json_response.length).to eq(4)
        end
      end
    end

    context 'ログイン中の自分について' do
      before do
        post login_path, params: { session: { email: user.email, password: user.password } }
        get users_path, as: :json
      end

      it '一覧に含まれない' do
        json_response = JSON.parse(response.body)
        expect(json_response.pluck('id')).not_to include(user.id)
      end
    end

    context '管理者以外の場合' do
      let(:general_user) { create(:user) }

      it 'ユーザー一覧を見られない' do
        post login_path, params: { session: { email: general_user.email, password: general_user.password } }
        get users_path
        expect(response).to redirect_to(root_url)
      end
    end
  end
  
  describe 'GET show' do
    let(:user) { create(:user) }

    before do
      post login_path, params: { session: { email: user.email, password: user.password } }
      get user_path(user), as: :json
    end
  
    context '1件のユーザーが存在する場合' do
      it "200 HTTPレスポンスを返す" do
        expect(response.status).to eq 200
      end


      it '指定されたユーザーを返す' do
        json_response = JSON.parse(response.body)
        expected_data = {
            'id' => user.id,
            'name' => user.name,
            'email' => user.email,
            'created_at' => user.created_at.as_json,
            'updated_at' => user.updated_at.as_json,
            'password_digest' => user.password_digest,
            'remember_digest' => user.remember_digest,
            'admin' => user.admin,
            'supervisor' => user.supervisor,
            'department' => user.department,
            'basic_time' => user.basic_time.as_json,
            'work_time' => user.work_time.as_json,
            'designated_work_start_time' => user.designated_work_start_time.as_json,
            'designated_work_end_time' => user.designated_work_end_time.as_json,
            'employee_number' => user.employee_number,
            'uid' => user.uid
          }
        expect(json_response).to eq(expected_data)
      end
    end
  end

  describe 'GET show (CSV形式)' do
    let(:user)  { create(:user) }
    let(:month) { Date.new(2026, 9, 1) }
    let!(:attendances) do
      (month..month.end_of_month).map { |day| create(:attendance, user: user, worked_on: day) }
    end
    let(:csv_rows) { CSV.parse(response.body.force_encoding("UTF-8").delete_prefix("\uFEFF")) }

    before do
      post login_path, params: { session: { email: user.email, password: user.password } }
    end

    it "表示月の勤怠をCSVでダウンロードできる" do
      get user_path(user, format: :csv, date: month)
      expect(response.media_type).to eq "text/csv"
      expect(response.headers["Content-Disposition"]).to include "attachment"
      expect(csv_rows.first).to eq %w[日付 曜日 出社時間 退社時間 備考]
      expect(csv_rows.size).to eq 1 + 30
    end

    it "申請中の値は出力せず、承認済みの実績を出力する" do
      attendance = attendances.first
      attendance.update!(started_at: Time.zone.local(2026, 9, 1, 9, 0), finished_at: Time.zone.local(2026, 9, 1, 18, 0))
      create(:attendance_correction_request, attendance: attendance,
             requested_started_at: Time.zone.local(2026, 9, 1, 10, 30),
             requested_finished_at: Time.zone.local(2026, 9, 1, 18, 0))

      get user_path(user, format: :csv, date: month)
      expect(csv_rows[1]).to eq ["2026/09/01", "火", "09:00", "18:00", nil]
    end

    it "日をまたぐ退社は「翌」を付ける" do
      attendances.second.update!(started_at: Time.zone.local(2026, 9, 2, 20, 0), finished_at: Time.zone.local(2026, 9, 3, 2, 0))
      get user_path(user, format: :csv, date: month)
      expect(csv_rows[2]).to eq ["2026/09/02", "水", "20:00", "翌02:00", nil]
    end

    it "=で始まる備考に ' を付ける" do
      attendances.first.update!(note: "=1+1")
      get user_path(user, format: :csv, date: month)
      expect(csv_rows[1][4]).to eq "'=1+1"
    end

    it "他人のCSVはリダイレクトされる" do
      other = create(:user)
      get user_path(other, format: :csv, date: month)
      expect(response).to redirect_to(root_url)
    end
  end
  
  describe 'GET new' do
    before do
      get new_user_path, as: :json
    end

    it "200 HTTPレスポンスを返す" do
      expect(response.status).to eq 200
    end

    it '新しいユーザーインスタンスが生成される' do
      json_response = JSON.parse(response.body)
      expected_data = {
        'admin' => false,
        'supervisor' => false,
        'basic_time' => Time.zone.now.change(hour: 8, min: 0, sec: 0).as_json,
        'work_time' => Time.zone.now.change(hour: 7, min: 30, sec: 0).as_json,
        'designated_work_start_time' => Time.zone.parse('2000-01-01 09:00:00').as_json,
        'designated_work_end_time' => Time.zone.parse('2000-01-01 18:00:00').as_json,
        'created_at' => nil,
        'department' => nil,
        'email' => nil,
        'id' => nil,
        'name' => nil,
        'password_digest' => nil,
        'remember_digest' => nil,
        'updated_at' => nil,
        'employee_number' => nil,
        'uid' => nil
      }
      expect(json_response).to eq(expected_data)
    end
  end
  
  describe 'POST create' do
    context '有効な値の場合' do
      let(:user_params) { { name: 'Test User', email: 'test@example.com', password: 'password', password_confirmation: 'password' } }
      let(:json_response) { JSON.parse(response.body) }
  
      before do
        post users_path, params: { user: user_params }, as: :json
      end
  
      it '201 Created ステータスコードを返す' do
        expect(response).to have_http_status(:created)
      end
  
      it 'ユーザーが生成される' do
        expect(json_response).to include({
          'admin' => false,
          'basic_time' => Time.zone.now.change(hour: 8, min: 0, sec: 0).as_json,
          'work_time' => Time.zone.now.change(hour: 7, min: 30, sec: 0).as_json,
          'department' => nil,
          'email' => 'test@example.com',
          'name' => 'Test User'
        })
        expect(json_response).to include('id', 'created_at', 'updated_at', 'password_digest')
      end
  
      it 'ユーザーがデータベースに保存される' do
        expect(User.last).to have_attributes(name: 'Test User', email: 'test@example.com')
      end
    end
  
    context '無効な値の場合' do
      before do
        post users_path, params: { user: { name: '', email: 'user@example.com', password: 'password', password_confirmation: 'password' } }, as: :json
      end
  
      it '422 Unprocessable Entity ステータスコードを返す' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
  
      it 'ユーザーが作成されない' do
        expect { 
          post users_path, params: { user: { name: '', email: 'user@example.com', password: 'password', password_confirmation: 'password' } }, as: :json 
        }.not_to change { User.count }
      end
  
      it 'エラーレスポンスが含まれている' do
        json_response = JSON.parse(response.body)
        expect(json_response).to be_present
      end
      
      it 'バリデーションメッセージで「名前を入力してください」を返す' do
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eq(['を入力してください'])
      end
    end
    
    describe 'PATCH update' do
      let(:user) { create(:user, name: 'Existing User', email: 'existing@example.com', password: 'password', password_confirmation: 'password') }
      let(:json_response) { JSON.parse(response.body) }
    
      context '有効な値の場合' do
        let(:user_params) { { name: 'Updated User', email: 'updated@example.com' } }
    
        before do
          post login_path, params: { session: { email: user.email, password: user.password } }
          patch user_path(user), params: { user: user_params }, as: :json
        end
    
        it "200 httpレスポンスを返す" do
          expect(response.status).to eq 200
        end
    
        it 'ユーザー情報が更新される' do
          expect(json_response).to include({
            'name' => 'Updated User',
            'email' => 'updated@example.com'
          })
          expect(json_response).to include('id', 'created_at', 'updated_at')
        end
    
        it 'ユーザーのデータベースで更新される' do
          user.reload
          expect(user).to have_attributes(name: 'Updated User', email: 'updated@example.com')
        end
      end
    
      context '無効な値の場合' do
        before do
          post login_path, params: { session: { email: user.email, password: user.password } }
          patch user_path(user), params: { user: { name: '', email: 'invalid@example.com' } }, as: :json
        end
    
        it '422 Unprocessable Entity ステータスコードを返す' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
    
        it 'ユーザー情報が更新されない' do
          user.reload
          expect(user).to have_attributes(name: 'Existing User', email: 'existing@example.com')
        end


        it 'エラーレスポンスが含まれている' do
          expect(json_response).to be_present
        end
    
        it 'バリデーションメッセージで「名前を入力してください」を返す' do
          expect(json_response['name']).to eq(['を入力してください'])
        end
      end
    end
    describe 'DELETE #destroy' do
      let(:admin_user) { create(:user, admin: true) }
      let(:target_user) { create(:user) }
    
      before do
        admin_user
        target_user
        post login_path, params: { session: { email: admin_user.email, password: admin_user.password } }
      end
    
      it 'ユーザーがデータベースから削除される' do
        expect {
          delete user_path(target_user)
        }.to change(User, :count).by(-1)
      end
  
      it '302 Found ステータスコードを返す' do
        delete user_path(target_user)
        expect(response).to have_http_status(:found)
      end
  
      it 'フラッシュメッセージで「「ユーザー名」のデータを削除しました」と返す' do
        delete user_path(target_user)
        expect(flash[:success]).to eq("#{target_user.name}のデータを削除しました。")
      end
    
      it 'ユーザー一覧ページにリダイレクトされる' do
        delete user_path(target_user)
        expect(response).to redirect_to(users_url)
      end

      it '自分自身は削除できない' do
        expect {
          delete user_path(admin_user)
        }.not_to change(User, :count)
        expect(flash[:danger]).to eq("自分自身は編集・削除できません。")
      end

      it '上長も削除できる' do
        supervisor = create(:user, supervisor: true)
        expect {
          delete user_path(supervisor)
        }.to change(User, :count).by(-1)
      end
    end
  end

  describe 'DELETE #destroy（管理者以外）' do
    let(:user)        { create(:user) }
    let(:target_user) { create(:user) }

    before do
      target_user
      post login_path, params: { session: { email: user.email, password: user.password } }
    end

    it '他のユーザーを削除できない' do
      expect { delete user_path(target_user) }.not_to change(User, :count)
      expect(response).to redirect_to(root_url)
    end
  end

  describe 'PATCH update_basic_info' do
    let(:admin)  { create(:user, admin: true) }
    let(:target) { create(:user) }
    let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
    let(:user_params) do
      { name: "変更後の名前", email: "changed@example.com", department: "総務部",
        employee_number: "1001", uid: "CARD1001",
        password: "newpass", password_confirmation: "newpass",
        basic_time: "08:00", designated_work_start_time: "09:30", designated_work_end_time: "18:30" }
    end

    context "管理者の場合" do
      before do
        post login_path, params: { session: { email: admin.email, password: admin.password } }
      end

      it "他のユーザーの9項目を変更できる" do
        patch update_basic_info_user_path(target), params: { user: user_params }, headers: turbo_stream_headers
        target.reload
        expect(target.name).to eq "変更後の名前"
        expect(target.email).to eq "changed@example.com"
        expect(target.department).to eq "総務部"
        expect(target.employee_number).to eq "1001"
        expect(target.uid).to eq "CARD1001"
        expect(target.authenticate("newpass")).to be_truthy
        expect(target.basic_time.strftime("%H:%M")).to eq "08:00"
        expect(target.designated_work_start_time.strftime("%H:%M")).to eq "09:30"
        expect(target.designated_work_end_time.strftime("%H:%M")).to eq "18:30"
      end

      it "パスワードを空欄にすると、パスワードは変わらない" do
        patch update_basic_info_user_path(target),
              params: { user: user_params.merge(password: "", password_confirmation: "") }, headers: turbo_stream_headers
        expect(target.reload.authenticate("password")).to be_truthy
      end

      it "社員番号とカードIDを空欄にすると、空(nil)で保存される" do
        patch update_basic_info_user_path(target),
              params: { user: user_params.merge(employee_number: "", uid: "") }, headers: turbo_stream_headers
        expect(target.reload.employee_number).to be_nil
        expect(target.uid).to be_nil
      end

      it "他のユーザーと同じ社員番号には変更できない" do
        create(:user, employee_number: "1001")
        patch update_basic_info_user_path(target), params: { user: user_params }, headers: turbo_stream_headers
        expect(target.reload.employee_number).to be_nil
      end

      it "自分自身は編集できない" do
        patch update_basic_info_user_path(admin), params: { user: user_params }, headers: turbo_stream_headers
        expect(admin.reload.name).not_to eq "変更後の名前"
      end

      it "保存したメッセージは、その場で表示し、次の画面には残さない" do
        patch update_basic_info_user_path(target), params: { user: user_params }, headers: turbo_stream_headers
        expect(response.body).to include "変更後の名前のユーザー情報を更新しました。"

        get users_path
        expect(response.body).not_to include "ユーザー情報を更新しました。"
      end
    end

    context "管理者以外の場合" do
      let(:user) { create(:user) }

      before do
        post login_path, params: { session: { email: user.email, password: user.password } }
      end

      it "他のユーザーを編集できない" do
        patch update_basic_info_user_path(target), params: { user: user_params }, headers: turbo_stream_headers
        expect(response).to redirect_to(root_url)
        expect(target.reload.name).not_to eq "変更後の名前"
      end
    end
  end

  describe 'POST import' do
    let(:admin) { create(:user, admin: true) }
    let(:header) do
      "name,email,affiliation,employee_number,uid,basic_work_time," \
        "designated_work_start_time,designated_work_end_time,superior,admin,password\n"
    end

    # テスト用のCSVファイルを作ります
    def csv_file(body, encoding: "UTF-8")
      file = Tempfile.new(["users", ".csv"])
      file.binmode
      file.write(body.encode(encoding))
      file.rewind
      Rack::Test::UploadedFile.new(file.path, "text/csv")
    end

    context "管理者の場合" do
      before do
        post login_path, params: { session: { email: admin.email, password: admin.password } }
      end

      it "CSVのユーザーを一括登録できる" do
        body = header +
               "山田太郎,yamada@example.com,総務部,1001,A001,08:00,09:00,18:00,true,false,password\n" \
               "鈴木花子,suzuki@example.com,営業部,1002,A002,07:30,10:00,19:00,false,false,password\n"

        expect { post import_users_path, params: { file: csv_file(body) } }.to change(User, :count).by(2)
        expect(flash[:success]).to eq "2件のユーザーを登録しました。"

        yamada = User.find_by(email: "yamada@example.com")
        expect(yamada.department).to eq "総務部"
        expect(yamada.employee_number).to eq "1001"
        expect(yamada.uid).to eq "A001"
        expect(yamada.basic_time.strftime("%H:%M")).to eq "08:00"
        expect(yamada.designated_work_start_time.strftime("%H:%M")).to eq "09:00"
        expect(yamada.supervisor).to be true
        expect(yamada.admin).to be false
        expect(yamada.authenticate("password")).to be_truthy
      end

      it "Shift_JISのCSVも読み込める" do
        body = header + "山田太郎,yamada@example.com,総務部,1001,A001,08:00,09:00,18:00,false,false,password\n"
        expect {
          post import_users_path, params: { file: csv_file(body, encoding: "Windows-31J") }
        }.to change(User, :count).by(1)
        expect(User.find_by(email: "yamada@example.com").name).to eq "山田太郎"
      end

      it "1行でもエラーがあれば、1件も登録しない" do
        body = header +
               "山田太郎,yamada@example.com,総務部,1001,A001,08:00,09:00,18:00,false,false,password\n" \
               ",noname@example.com,営業部,1002,A002,08:00,09:00,18:00,false,false,password\n"

        expect { post import_users_path, params: { file: csv_file(body) } }.not_to change(User, :count)
        expect(flash[:danger]).to include "3行目"
      end

      it "ヘッダーが足りないと取り込まない" do
        expect {
          post import_users_path, params: { file: csv_file("name,email\n山田太郎,yamada@example.com\n") }
        }.not_to change(User, :count)
        expect(flash[:danger]).to include "ヘッダーが足りません"
      end

      it "ファイルを選ばずに送るとエラーメッセージを出す" do
        post import_users_path
        expect(flash[:danger]).to eq "CSVファイルを選択してください。"
      end

      it "エラーの行が多くても、表示は10件までにして500にならない" do
        long_error_row = ",not-an-email,A,#{'9' * 21},#{'C' * 21},,,,false,false,123\n"
        post import_users_path, params: { file: csv_file(header + (long_error_row * 100)) }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:danger]).to include "ほか90件のエラーがあります。"
      end

      it "ヘッダーの前後に空白があっても読み込める" do
        spaced_header = header.split(",").map { |h| " #{h.strip} " }.join(",") + "\n"
        body = spaced_header + "山田太郎,yamada@example.com,総務部,1001,A001,08:00,09:00,18:00,false,false,password\n"
        expect { post import_users_path, params: { file: csv_file(body) } }.to change(User, :count).by(1)
        expect(User.find_by(email: "yamada@example.com").name).to eq "山田太郎"
      end

      it "ヘッダーだけのCSVはエラーになる" do
        expect { post import_users_path, params: { file: csv_file(header) } }.not_to change(User, :count)
        expect(flash[:danger]).to include "登録するユーザーがありません。"
      end

      it "エラーの後のページ送りのリンクは、一覧を指す" do
        create_list(:user, 31)
        post import_users_path, params: { file: csv_file(header + ",x,,,,,,,false,false,password\n") }
        expect(response.body).to include 'href="/users?page=2"'
        expect(response.body).not_to include "/users/import?page="
      end
    end

    context "管理者以外の場合" do
      let(:user) { create(:user) }

      before do
        post login_path, params: { session: { email: user.email, password: user.password } }
      end

      it "インポートできない" do
        body = header + "山田太郎,yamada@example.com,総務部,1001,A001,08:00,09:00,18:00,false,false,password\n"
        expect { post import_users_path, params: { file: csv_file(body) } }.not_to change(User, :count)
        expect(response).to redirect_to(root_url)
      end
    end
  end
end