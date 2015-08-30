class Users::SessionsController < Devise::SessionsController
  force_ssl only: [:create, :new], if: -> { Rails.env.production? }
end
