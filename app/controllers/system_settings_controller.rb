class SystemSettingsController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user

  # システム全体の基本情報を設定するページ(設定項目は今後追加します)
  def edit
  end
end
