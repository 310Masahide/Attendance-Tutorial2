class CreateAttendanceCorrectionRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :attendance_correction_requests do |t|
      t.references :attendance, null: false, foreign_key: true, index: { unique: true }
      t.references :user, null: false, foreign_key: true
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.datetime :requested_started_at
      t.datetime :requested_finished_at
      t.string :note
      t.integer :status, null: false, default: 1
      t.boolean :applicant_confirmed, null: false, default: false

      t.timestamps
    end
  end
end
