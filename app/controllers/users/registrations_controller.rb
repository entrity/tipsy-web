class Users::RegistrationsController < Devise::RegistrationsController

  protected

    def after_update_path_for(resource)
      edit_user_registration_path(resource)
    end

    def update_resource(resource, params)
      if [:password, :email].any?{|key| user_params.has_key?(key) }
        resource.update_with_password(user_params)
      else
        resource.update_without_password(user_params)
      end
    end

    def user_params
      params.require(:user).permit(
        :email, :password, :current_password, :password_confirmation,
        :name, :nickname,
        :bio, :location, :twitter,
        :no_profanity,
        :no_alcohol,
      )
    end

end
