require 'rails_helper'

RSpec.describe MonthlyApproval, type: :model do
  describe 'バリデーション' do
    it '月初以外の日付は無効' do
      monthly_approval = build(:monthly_approval, month: Date.current.beginning_of_month + 1.day)

      expect(monthly_approval).to be_invalid
      expect(monthly_approval.errors[:month]).to be_present
    end

    it '同じユーザー・同じ月の申請は2件作成できない' do
      user = create(:user)
      month = Date.current.beginning_of_month
      create(:monthly_approval, user: user, month: month)
      second = build(:monthly_approval, user: user, month: month)

      expect(second).to be_invalid
      expect(second.errors[:user_id]).to be_present
    end

    it '違う月であれば同じユーザーでも作成できる' do
      user = create(:user)
      create(:monthly_approval, user: user, month: Date.current.beginning_of_month)
      second = build(:monthly_approval, user: user, month: Date.current.beginning_of_month + 1.month)

      expect(second).to be_valid
    end
  end

  describe '#decided?' do
    it '承認済みの場合はtrueを返す' do
      expect(build(:monthly_approval, status: :approved).decided?).to be true
    end

    it '申請中の場合はfalseを返す' do
      expect(build(:monthly_approval, status: :pending).decided?).to be false
    end
  end
end
