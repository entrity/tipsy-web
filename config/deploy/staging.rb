server 'tipsyology.qa', user: 'deploy', roles: %w{app db web}, my_property: :my_value

set :rvm_ruby_string, '2.2.0'
set :rvm_type, :system
set :branch, 'develop'
set :rails_env, 'production'

