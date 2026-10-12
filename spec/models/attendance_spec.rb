require "rails_helper"

RSpec.describe Attendance, type: :model do
  describe ".working_on" do
    let(:today) { Date.new(2026, 10, 10) }
    let(:nine)  { today.in_time_zone.change(hour: 9) }

    it "出社時刻があり、退社時刻が無い勤怠だけを返す" do
      working   = create(:attendance, worked_on: today, started_at: nine)
      finished  = create(:attendance, worked_on: today, started_at: nine, finished_at: today.in_time_zone.change(hour: 18))
      not_yet   = create(:attendance, worked_on: today)
      yesterday = create(:attendance, worked_on: today - 1, started_at: (today - 1).in_time_zone.change(hour: 9))

      result = Attendance.working_on(today)
      expect(result).to include(working)
      expect(result).not_to include(finished, not_yet, yesterday)
    end
  end
end
