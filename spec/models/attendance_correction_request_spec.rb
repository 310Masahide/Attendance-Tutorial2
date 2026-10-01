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

  describe ".correction_logs" do
    let(:attendance) do
      create(:attendance, worked_on: Date.new(2026, 2, 1),
                          started_at: Time.zone.local(2026, 2, 1, 10, 0),
                          finished_at: Time.zone.local(2026, 2, 1, 18, 0))
    end

    # 申請して承認する(承認時に変更前の時刻が記録される)
    def approve_change(attendance, started_hour, finished_hour)
      request = create(:attendance_correction_request, attendance: attendance,
                       requested_started_at: Time.zone.local(2026, 2, 1, started_hour, 0),
                       requested_finished_at: Time.zone.local(2026, 2, 1, finished_hour, 0))
      request.update!(status: :approved)
    end

    it "同じ日を複数回変更した場合、最初の変更前 ⇨ 最後の変更後 の1行にまとめる" do
      approve_change(attendance, 11, 19)
      approve_change(attendance, 12, 20)
      approve_change(attendance, 13, 21)

      logs = AttendanceCorrectionRequest.correction_logs
      expect(logs.size).to eq 1
      expect(logs.first.before_started_at).to eq Time.zone.local(2026, 2, 1, 10, 0)
      expect(logs.first.before_finished_at).to eq Time.zone.local(2026, 2, 1, 18, 0)
      expect(logs.first.after_started_at).to eq Time.zone.local(2026, 2, 1, 13, 0)
      expect(logs.first.after_finished_at).to eq Time.zone.local(2026, 2, 1, 21, 0)
    end

    it "承認されていない申請はログに含めない" do
      create(:attendance_correction_request, attendance: attendance)   # 申請中のまま
      expect(AttendanceCorrectionRequest.correction_logs).to be_empty
    end

        it "承認日は最後に承認した日時になる" do
      travel_to Time.zone.local(2026, 2, 3, 10, 0) do
        approve_change(attendance, 11, 19)
      end
      travel_to Time.zone.local(2026, 2, 5, 15, 0) do
        approve_change(attendance, 12, 20)
      end

      expect(AttendanceCorrectionRequest.correction_logs.first.approved_at).to eq Time.zone.local(2026, 2, 5, 15, 0)
    end
  end
end
