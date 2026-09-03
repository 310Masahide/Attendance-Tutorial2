require 'rails_helper'

RSpec.describe OvertimeRequest, type: :model do
  let(:applicant)  { create(:user, work_time: "2026-08-25T07:30:00+09:00") }
  let(:supervisor) { create(:user, supervisor: true) }

  describe '#overtime_hours' do
    before { create(:attendance, user: applicant, worked_on: Date.new(2026, 8, 25), started_at: Time.zone.parse("2026-08-25 09:00")) }

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
  end

  describe 'approver のバリデーション' do
    it '上長でないユーザーは承認者に指定できない' do
      overtime_request = build(:overtime_request, user: applicant, approver: create(:user, supervisor: false))
      expect(overtime_request).to be_invalid
    end

    it '自分自身は承認者に指定できない' do
      overtime_request = build(:overtime_request, user: applicant, approver: applicant)
      expect(overtime_request).to be_invalid
    end
  end
end