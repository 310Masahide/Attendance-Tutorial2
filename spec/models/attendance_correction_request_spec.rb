require 'rails_helper'

RSpec.describe AttendanceCorrectionRequest, type: :model do
  describe 'バリデーション' do
    it '同じattendanceに2件目のpending申請は作成できない' do
      attendance = create(:attendance)
      create(:attendance_correction_request, attendance: attendance, user: attendance.user, status: :pending)
      second = build(:attendance_correction_request, attendance: attendance, user: attendance.user, status: :pending)

      expect(second).to be_invalid
      expect(second.errors[:attendance_id]).to be_present
    end

    it '却下済みの申請がある状態でも、新しいpending申請は作成できる' do
      attendance = create(:attendance)
      create(:attendance_correction_request, attendance: attendance, user: attendance.user, status: :rejected)
      second = build(:attendance_correction_request, attendance: attendance, user: attendance.user, status: :pending)

      expect(second).to be_valid
    end

    it '退社時間より遅い出社時間は無効' do
      request = build(:attendance_correction_request,
                       requested_started_at: Time.zone.local(2026, 1, 1, 20, 0),
                       requested_finished_at: Time.zone.local(2026, 1, 1, 9, 0))

      expect(request).to be_invalid
      expect(request.errors[:requested_started_at]).to be_present
    end
  end

  describe '#apply_to_attendance' do
    it '承認されると、実際のattendanceにrequested_started_at/finished_at/noteが反映される' do
      attendance = create(:attendance, started_at: Time.zone.local(2026, 1, 1, 8, 0),
                                        finished_at: Time.zone.local(2026, 1, 1, 17, 0), note: "元のメモ")
      request = create(:attendance_correction_request, attendance: attendance, user: attendance.user,
                        requested_started_at: Time.zone.local(2026, 1, 1, 9, 0),
                        requested_finished_at: Time.zone.local(2026, 1, 1, 18, 0),
                        note: "変更後のメモ", status: :pending)

      request.update!(status: :approved)
      attendance.reload

      expect(attendance.started_at).to eq Time.zone.local(2026, 1, 1, 9, 0)
      expect(attendance.finished_at).to eq Time.zone.local(2026, 1, 1, 18, 0)
      expect(attendance.note).to eq "変更後のメモ"
    end

    it '却下時はattendanceを変更しない' do
      attendance = create(:attendance, started_at: Time.zone.local(2026, 1, 1, 8, 0),
                                        finished_at: Time.zone.local(2026, 1, 1, 17, 0))
      request = create(:attendance_correction_request, attendance: attendance, user: attendance.user,
                        requested_started_at: Time.zone.local(2026, 1, 1, 9, 0),
                        requested_finished_at: Time.zone.local(2026, 1, 1, 18, 0), status: :pending)

      request.update!(status: :rejected)
      attendance.reload

      expect(attendance.started_at).to eq Time.zone.local(2026, 1, 1, 8, 0)
      expect(attendance.finished_at).to eq Time.zone.local(2026, 1, 1, 17, 0)
    end
  end
end
