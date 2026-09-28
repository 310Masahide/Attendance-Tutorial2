module AdminOrCorrectUserScoped
  extend ActiveSupport::Concern

  private

    def admin_or_correct_user
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "権限がありません。"
        redirect_to(root_url)
      end
    end
end
