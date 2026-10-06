class CreateOffices < ActiveRecord::Migration[7.1]
  def change
    create_table :offices do |t|
      t.integer :office_number, null: false
      t.string :name, null: false
      t.string :office_type, null: false

      t.timestamps
    end
    add_index :offices, :office_number, unique: true
    add_index :offices, :name, unique: true
  end
end
