class CreateOffices < ActiveRecord::Migration[7.1]
  def change
    create_table :offices do |t|
      t.integer :office_number, null: false
      t.string :name, null: false
      t.string :attendance_type, null: false

      t.timestamps
      t.index :office_number, unique: true
      t.index :name, unique: true
    end
  end
end
