class RemoveApplicantConfirmedFromAttendanceCorrectionRequests < ActiveRecord::Migration[7.1]
  def change
    remove_column :attendance_correction_requests, :applicant_confirmed, :boolean, default: false, null: false
  end
end

