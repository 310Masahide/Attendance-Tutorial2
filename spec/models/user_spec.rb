require 'rails_helper'


RSpec.describe User, type: :model do
  let(:user) { User.new(name: "Valid Name", email: "test@user.com", password: "password") }


  describe 'バリデーション' do
    context '名前が設定されていて、かつ50文字以下の場合' do
      it 'バリデーションが通る' do
        expect(user.valid?).to eq(true)
      end
    end


    context '名前が設定されていない場合' do
      it 'バリデーションが通らない' do
        user.name = nil
        expect(user.valid?).to eq(false)
      end
    end


    context '名前が51文字以上の場合' do
      it 'バリデーションが通らない' do
        user.name = 'a' * 51
        expect(user.valid?).to eq(false)
      end
    end


    context 'メールアドレスが正しく設定されている場合' do
      it 'バリデーションが通る' do
        expect(user.valid?).to eq(true)
      end
    end


    context 'メールアドレスが空の場合' do
      it 'バリデーションが通らない' do
        user.email = nil
        expect(user.valid?).to eq(false)
      end
    end


    context 'メールアドレスが100文字以下の場合' do
      it 'バリデーションが通る' do
        user.email = 'a' * 7 + '@example.com'
        expect(user.valid?).to eq(true)
      end
    end


    context 'メールアドレスが100文字を超える場合' do
      it 'バリデーションが通らない' do
        user.email = 'a' * 101 + '@example.com'
        expect(user.valid?).to eq(false)
      end
    end


    context 'メールアドレスのフォーマットが不適切な場合' do
      it 'バリデーションが通らない' do
        user.email = 'invalid_email'
        expect(user.valid?).to eq(false)
      end
    end


    context '同じメールアドレスを持つユーザーが既に存在する場合' do
      before do
        User.create!(name: "Existing User", email: "duplicate@example.com", password: "password")
      end


      it 'バリデーションが通らない' do
        user.email = 'duplicate@example.com'
        expect(user.valid?).to eq(false)
      end
    end


    context 'パスワードが設定されている場合' do
      it 'バリデーションが通る' do
        expect(user.valid?).to eq(true)
      end
    end


    context 'パスワードが設定されていない場合' do
      it 'バリデーションが通らない' do
        user.password = nil
        expect(user.valid?).to eq(false)
      end
    end


    context 'パスワードが6文字未満の場合' do
      it 'バリデーションが通らない' do
        user.password = '12345'
        expect(user.valid?).to eq(false)
      end
    end


    context 'パスワードが6文字以上の場合' do
      it 'バリデーションが通る' do
        user.password = '123456'
        expect(user.valid?).to eq(true)
      end
    end
  end
end