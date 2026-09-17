class ChangeAttendanceIdIndexOnAttendanceCorrectionRequests < ActiveRecord::Migration[7.1]
  def change
    add_index :attendance_correction_requests, :attendance_id, name: "index_attendance_correction_requests_on_attendance_id_tmp"
    remove_index :attendance_correction_requests, :attendance_id, name: "index_attendance_correction_requests_on_attendance_id"
    rename_index :attendance_correction_requests,
                 "index_attendance_correction_requests_on_attendance_id_tmp",
                 "index_attendance_correction_requests_on_attendance_id"
  end
end

