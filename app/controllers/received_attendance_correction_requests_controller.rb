class ReceivedAttendanceCorrectionRequestsController < ApplicationController
  before_action :logged_in_user
  include SupervisorScoped
  include BulkStatusUpdatable

  def index
    return redirect_to(@supervisor) unless turbo_frame_request?

    @requests_by_applicant = pending_requests_by_applicant
  end

  def bulk_update
    failed_count = apply_status_changes(@supervisor.received_attendance_correction_requests, submitted_changes(:attendance_correction_requests))
    flash.now[:danger] = "#{failed_count}件の更新に失敗しました。" if failed_count.positive?
    @requests_by_applicant = pending_requests_by_applicant
  end

  private

    def pending_requests_by_applicant
      group_pending_by_applicant(@supervisor.received_attendance_correction_requests,
                                  includes: [:attendance, :user], joins: :attendance, order: "attendances.worked_on")
    end
end

