require "rails_helper"

RSpec.describe Office, type: :model do
  it "拠点名・勤怠種類があれば有効" do
    expect(build(:office)).to be_valid
  end

  it "拠点番号は1から自動で採番される" do
    expect(create(:office).office_number).to eq 1
    expect(create(:office).office_number).to eq 2
  end

  it "拠点番号は、登録済みの一番大きい番号の次になる" do
    create(:office, office_number: 10)
    expect(create(:office).office_number).to eq 11
  end

  it "修正しても拠点番号は変わらない" do
    office = create(:office)
    office.update!(name: "名前を変更")
    expect(office.reload.office_number).to eq 1
  end

  it "拠点名が無いと無効" do
    expect(build(:office, name: "")).not_to be_valid
  end

  it "拠点名が重複していると無効" do
    create(:office, name: "本社")
    expect(build(:office, name: "本社")).not_to be_valid
  end

  it "勤怠種類が出勤・退勤以外だと無効" do
    expect(build(:office, attendance_type: "休憩")).not_to be_valid
  end
end
