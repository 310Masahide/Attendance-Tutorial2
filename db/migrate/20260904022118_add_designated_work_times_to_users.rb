class AddDesignatedWorkTimesToUsers < ActiveRecord::Migration[7.1]
  def change
    # DBにはUTCで保存され、アプリのタイムゾーン(JST, UTC+9)で表示されるため、
    # 意図した時刻(09:00/18:00 JST)より9時間早い値をデフォルトとして指定する。
    add_column :users, :designated_work_start_time, :time, null: false, default: "00:00"
    add_column :users, :designated_work_end_time, :time, null: false, default: "09:00"
  end
end
