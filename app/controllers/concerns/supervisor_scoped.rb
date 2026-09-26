module SupervisorScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_supervisor
    before_action :correct_supervisor
  end

  private

    def set_supervisor
      @supervisor = User.find(params[:id])
    end

    def correct_supervisor
      return if current_user?(@supervisor) && current_user.supervisor?

      flash[:danger] = "権限がありません。"
      redirect_to(root_url)
    end
end
