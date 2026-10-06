require "csv"

class User < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :overtime_requests, dependent: :destroy
  has_many :received_overtime_requests, class_name: "OvertimeRequest", foreign_key: :approver_id, dependent: :destroy
  has_many :received_attendance_correction_requests, class_name: "AttendanceCorrectionRequest", foreign_key: :approver_id, dependent: :destroy
  has_many :attendance_correction_requests, dependent: :destroy
  has_many :monthly_approvals, dependent: :destroy
  has_many :received_monthly_approvals, class_name: "MonthlyApproval", foreign_key: :approver_id, dependent: :destroy

  scope :supervisors, -> { where(supervisor: true) }

  attr_accessor :remember_token
  before_save { self.email = email.downcase }
  # basic_time/work_timeは時刻のみが意味を持つため、生成日時をマイグレーション実行日に固定せず常に当日の日付で設定します。
  after_initialize :set_default_times, if: :new_record?

  validates :name,  presence: true, length: { maximum: 50 }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 100 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  validates :department, length: { in: 2..30 }, allow_blank: true
  # 空欄は NULL として保存します(空文字 "" のままだと、2人目の空欄が unique インデックスに引っかかるため)
  normalizes :employee_number, :uid, with: ->(value) { value.strip.presence }
  validates :employee_number, length: { maximum: 20 }, uniqueness: true, allow_nil: true
  validates :uid, length: { maximum: 20 }, uniqueness: true, allow_nil: true
  validates :basic_time, presence: true
  validates :work_time, presence: true
  validates :designated_work_start_time, presence: true
  validates :designated_work_end_time, presence: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  def User.digest(string)
    cost = 
      if ActiveModel::SecurePassword.min_cost
        BCrypt::Engine::MIN_COST
      else
        BCrypt::Engine.cost
      end
    BCrypt::Password.create(string, cost: cost)
  end

  def User.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  def approver_candidates
    User.supervisors.where.not(id: id)
  end

  CSV_IMPORT_HEADERS = %w[name email affiliation employee_number uid basic_work_time
                       designated_work_start_time designated_work_end_time superior admin password].freeze
  CSV_FIRST_DATA_LINE = 2 # 1行目はヘッダーなので、データは2行目から
              

  # CSVファイルからユーザーを一括登録します。1行でもエラーがあれば、1件も登録しません
  # 戻り値: [登録した件数, エラーメッセージの配列]
  def self.import_csv(file)
    rows = CSV.parse(read_csv_text(file), headers: true, skip_blanks: true,
                     header_converters: ->(header) { header&.strip })
    missing_headers = CSV_IMPORT_HEADERS - rows.headers
    return [0, ["CSVのヘッダーが足りません（#{missing_headers.join('、')}）"]] if missing_headers.any?
    return [0, ["登録するユーザーがありません。"]] if rows.empty?

    errors = []
    transaction do
      rows.each.with_index(CSV_FIRST_DATA_LINE) do |row, line_number|
        user = new(csv_row_attributes(row))
        errors << "#{line_number}行目: #{user.errors.full_messages.join('、')}" unless user.save
      end
      raise ActiveRecord::Rollback if errors.any?
    end
    [errors.empty? ? rows.size : 0, errors]
  rescue CSV::MalformedCSVError, EncodingError
    [0, ["CSVファイルを読み込めませんでした。ファイルの形式と文字コードを確認してください。"]]
  end

  # Excelで保存したCSV(Shift_JIS)と、UTF-8(BOM付きも可)の両方を読めるようにします
  def self.read_csv_text(file)
    text = File.binread(file.path).force_encoding(Encoding::UTF_8)
    text = text.encode(Encoding::UTF_8, Encoding::Windows_31J) unless text.valid_encoding?
    text.delete_prefix("\uFEFF")
  end
  private_class_method :read_csv_text

  # CSVの1行を、Userの属性に変換します(ヘッダー名とカラム名が違うものはここで対応付けます)
  # 空欄の項目は渡さず、新規登録時の初期値を使います
  def self.csv_row_attributes(row)
    {
      name:                       row["name"],
      email:                      row["email"],
      department:                 row["affiliation"],
      employee_number:            row["employee_number"],
      uid:                        row["uid"],
      basic_time:                 row["basic_work_time"],
      designated_work_start_time: row["designated_work_start_time"],
      designated_work_end_time:   row["designated_work_end_time"],
      supervisor:                 csv_boolean(row["superior"]),
      admin:                      csv_boolean(row["admin"]),
      password:                   row["password"],
      password_confirmation:      row["password"]
    }.transform_values { |value| value.is_a?(String) ? value.strip.presence : value }.compact
  end
  private_class_method :csv_row_attributes

  # CSVの true / false などの値を、真偽値に変換します(空欄は false)
  def self.csv_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value&.strip) || false
  end
  private_class_method :csv_boolean


  private

  def set_default_times
    self.basic_time = Time.zone.now.change(hour: 8, min: 0, sec: 0)
    self.work_time = Time.zone.now.change(hour: 7, min: 30, sec: 0)
  end
end
