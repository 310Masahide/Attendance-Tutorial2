class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:index, :show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info,
                                        :import]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info, :import]
  before_action :reject_self, only: [:destroy, :edit_basic_info, :update_basic_info]
  before_action :viewable_user, only: :show
  before_action :set_one_month, only: :show

  def index
    @users = users_for_index

    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def show
    return send_attendances_csv if request.format.csv?

    @worked_sum = @attendances.where.not(started_at: nil).count
    @overtime_requests_by_date = @user.overtime_requests.includes(:approver).index_by(&:worked_on)
    @monthly_approval = @user.monthly_approvals.find_or_initialize_by(month: @first_day)
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end

  def new
    @user = User.new

    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end


  def create
    @user = User.new(user_params)
    respond_to do |format|
      if @user.save
        log_in @user
        flash[:success] = '新規作成に成功しました。'
        format.html { redirect_to @user }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end


  def edit
  end


  def update
      respond_to do |format|
        if @user.update(user_params)
          flash[:success] = "ユーザー情報を更新しました。"
          format.html { redirect_to @user }
          format.json { render json: @user, status: :ok }
        else
          format.html { render :edit }
          format.json { render json: @user.errors, status: :unprocessable_entity }     
        end
      end
    end


  def destroy
    if @user.destroy
      flash[:success] = "#{ERB::Util.html_escape(@user.name)}のデータを削除しました。"
    else
      flash[:danger] = "#{ERB::Util.html_escape(@user.name)}の削除に失敗しました。#{@user.errors.full_messages.join('、')}"
    end

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end

  # CSVインポートの結果に表示するエラーの最大件数(多すぎると画面が長くなるため)
  MAX_IMPORT_ERRORS_SHOWN = 10

  # CSVファイルからユーザーを一括登録します
  def import
    unless params[:file].respond_to?(:path)
      flash[:danger] = "CSVファイルを選択してください。"
      return redirect_to users_url
    end

    imported_count, errors = User.import_csv(params[:file])
    if errors.empty?
      flash[:success] = "#{imported_count}件のユーザーを登録しました。"
      return redirect_to users_url
    end

    # エラーは件数も長さも決まらないので、Cookie を使う flash ではなく、
    # その場で一覧を表示する flash.now で出します(CookieOverflow を防ぐため)
    shown_errors = errors.first(MAX_IMPORT_ERRORS_SHOWN)
    shown_errors << "ほか#{errors.size - shown_errors.size}件のエラーがあります。" if errors.size > shown_errors.size
    flash.now[:danger] = "インポートできませんでした。<br>" + shown_errors.map { |error| ERB::Util.html_escape(error) }.join("<br>")
    @users = users_for_index
    render :index, status: :unprocessable_entity
  end

  def edit_basic_info
    @user = User.find(params[:id])

    respond_to do |format|
      format.html { render partial: 'users/edit_basic_info', locals: { user: @user } } # 修正
      format.turbo_stream
    end
  end

  def update_basic_info
    if @user.update(basic_info_params)
      flash[:success] = "#{ERB::Util.html_escape(@user.name)}のユーザー情報を更新しました。"
    else
      flash[:danger] = "#{ERB::Util.html_escape(@user.name)}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
  
    respond_to do |format|
      format.html { redirect_to users_url }
      format.turbo_stream
    end
  end

  private

  # ユーザー一覧に出すユーザー(ログイン中の自分は出さない)
  def users_for_index
    User.where.not(id: current_user.id).order(:id).paginate(page: params[:page])
  end


  def send_attendances_csv
    send_data @attendances.to_csv,
              filename: "#{@user.name}_#{@first_day.strftime('%Y年%m月')}_勤怠.csv",
              type: :csv
  end

  # 管理者でも、ユーザー一覧からは自分自身を編集・削除できません
  def reject_self
    return unless current_user?(@user)

    flash[:danger] = "自分自身は編集・削除できません。"
    redirect_to users_url
  end

  def viewable_user
    return if current_user?(@user) || current_user.admin?
    return if current_user.received_overtime_requests.exists?(user_id: @user.id)
    return if current_user.received_attendance_correction_requests.exists?(user_id: @user.id)
    return if current_user.received_monthly_approvals.exists?(user_id: @user.id)

    flash[:danger] = "閲覧権限がありません。"
    redirect_to(root_url)
  end

  def user_params
    params.require(:user).permit(:name, :email, :department, :password, :password_confirmation)
  end

  def basic_info_params
    params.require(:user).permit(:name, :email, :department, :employee_number, :uid,
                                 :password, :password_confirmation,
                                 :basic_time, :designated_work_start_time, :designated_work_end_time)
  end
end
