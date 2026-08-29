class CreateOvertimeRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :overtime_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.date :worked_on
      t.string :reason

      t.timestamps
    end
  end
end
