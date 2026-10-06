class OfficesController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user
  before_action :set_office, only: [:edit, :update, :destroy]

  # 拠点情報の一覧
  def index
    @offices = Office.order(:office_number)
  end

  # 拠点情報の追加画面
  def new
    @office = Office.new
  end

  # 拠点情報を追加する
  def create
    @office = Office.new(office_params)
    if @office.save
      flash[:success] = "拠点情報を追加しました。"
      redirect_to offices_url
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 拠点情報の編集画面
  def edit
  end

  # 拠点情報を更新する
  def update
    if @office.update(office_params)
      flash[:success] = "拠点情報を更新しました。"
      redirect_to offices_url
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 拠点情報を削除する
  def destroy
    @office.destroy
    flash[:success] = "#{@office.name}を削除しました。"
    redirect_to offices_url, status: :see_other
  end

  private

    def set_office
      @office = Office.find(params[:id])
    end

    def office_params
      params.require(:office).permit(:office_number, :name, :office_type)
    end
end
