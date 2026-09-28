require 'rails_helper'

RSpec.describe OvertimeRequest, type: :model do
  let(:applicant) do
    create(:user, designated_work_start_time: "2026-08-25T09:00:00+09:00",
                  designated_work_end_time: "2026-08-25T16:30:00+09:00")
  end
  let(:supervisor) { create(:user, supervisor: true) }

  describe '#overtime_hours' do
    it '定時終了(16:30)を1時間超えた申請は 1.0 を返す' do
      overtime_request = build(:overtime_request, user: applicant, approver: supervisor,
                               worked_on: Date.new(2026, 8, 25), finished_hour: 17, finished_minute: 30)
      expect(overtime_request.overtime_hours).to eq 1.0
    end

    it '日をまたぐ申請は24時間を足して計算する' do
      overtime_request = build(:overtime_request, user: applicant, approver: supervisor,
                               worked_on: Date.new(2026, 8, 25), finished_hour: 1, finished_minute: 0,
                               finishes_next_day: true)
      expect(overtime_request.overtime_hours).to eq 8.5
    end

    it '出勤前の未来日でも指定勤務終了時間を基準に計算する' do
      overtime_request = build(:overtime_request, user: applicant, approver: supervisor,
                               worked_on: Date.tomorrow, finished_hour: 20, finished_minute: 0)
      expect(applicant.attendances.exists?(worked_on: Date.tomorrow)).to be false
      expect(overtime_request.overtime_hours).to eq 3.5
    end
  end

  describe 'approver のバリデーション' do
    it '上長でないユーザーは承認者に指定できない' do
      overtime_request = build(:overtime_request, user: applicant, approver: create(:user, supervisor: false))
      expect(overtime_request).to be_invalid
      expect(overtime_request.errors[:approver]).to include("は上長を指定してください")
    end

    it '自分自身は承認者に指定できない' do
      supervisor_self = create(:user, supervisor: true)
      overtime_request = build(:overtime_request, user: supervisor_self, approver: supervisor_self)
      expect(overtime_request).to be_invalid
      expect(overtime_request.errors[:approver_id]).to include("には自分自身を指定できません")
    end
  end
end