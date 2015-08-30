class Users::RegistrationsController < Devise::RegistrationsController
  force_ssl only: [:create, :new], if: -> { Rails.env.production? }

  protected

    def after_update_path_for(resource)
      edit_user_registration_path(resource)
    end

    def update_resource(resource, sanitized_params)
      if [:password, :email].any?{|key| sanitized_params.has_key?(key) }
        resource.update_with_password(sanitized_params)
      else
        resource.update_without_password(sanitized_params)
      end
    end

    def account_update_params
      super.merge(params.require(:user).permit([
        {:photo_data => [:data_url, :filename]},
        :name,
        :nickname,
        :location,
        :twitter,
        :bio,
        :no_profanity,
        :no_alochol,
        :password,
        :email,
        :password_confirmation,
        :current_password,
      ]))
    end

end
