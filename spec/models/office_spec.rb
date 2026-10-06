require "rails_helper"

RSpec.describe Office, type: :model do
  it "拠点番号・拠点名・拠点種類があれば有効" do
    expect(build(:office)).to be_valid
  end

  it "拠点番号が無いと無効" do
    expect(build(:office, office_number: nil)).not_to be_valid
  end

  it "拠点番号が0以下だと無効" do
    expect(build(:office, office_number: 0)).not_to be_valid
  end

  it "拠点番号が重複していると無効" do
    create(:office, office_number: 1)
    expect(build(:office, office_number: 1)).not_to be_valid
  end

  it "拠点名が重複していると無効" do
    create(:office, name: "本社")
    expect(build(:office, name: "本社")).not_to be_valid
  end

  it "拠点種類が出勤・退勤以外だと無効" do
    expect(build(:office, office_type: "休憩")).not_to be_valid
  end
end
