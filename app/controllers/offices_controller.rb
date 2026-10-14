class OfficesController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user
  before_action :set_office, only: [:edit, :update, :destroy]

  def index
    @offices = Office.order(:office_number)
  end

  def new
    @office = Office.new
  end

  def create
    @office = Office.new(office_params)
    if @office.save
      flash[:success] = "拠点登録完了しました"
      redirect_to offices_url
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @office.update(office_params)
      flash[:success] = "拠点情報を修正しました"
      redirect_to offices_url
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @office.destroy
    flash[:success] = "#{ERB::Util.html_escape(@office.name)}を削除しました"
    redirect_to offices_url, status: :see_other
  end

  private

    def set_office
      @office = Office.find(params[:id])
    end

    def office_params
      params.require(:office).permit(:name, :attendance_type)
    end
end
