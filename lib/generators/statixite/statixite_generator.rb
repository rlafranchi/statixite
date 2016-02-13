module Statixite
  class StatixiteGenerator < Rails::Generators::Base

    def create_initializer_file
      create_file "config/initializers/statixite.rb", content
    end

    private

    def content
<<EOF
Statixite.setup do |config|
  # Used for Media Uploader
  # Valid options -
  # :file which commit media files directly to the associated site repo
  # :fog use Fog::Storage => A carrierwave.rb initializer file is required: see https://github.com/carrierwaveuploader/carrierwave 
  config.carrierwave_storage = :file

  # Where to deploy
  # Valid options -
  # :local stores sites at /path/to/app/sites/:site_name/build
  # :github pushes sites to your github account requires github creds and ssh access to account
  # :fog pushes sites using fog storage requires fog creds tested against S3 and Rackspace Cloud Files
  config.deploy_sites_to = :local

  # Deploying sites to github requires a personal access token to create repos
  # github creds => get personal token from github https://github.com/blog/1509-personal-api-tokens
  # config.github_user = username
  # config.github_token = ENV["GITHUB_TOKEN"]

  # fog creds AWS S3 example
  # config.fog_credentials = {
  #   :provider                 => 'AWS',
  #   :aws_access_key_id        => ENV["AWS_ACCESS_KEY_ID"],
  #   :aws_secret_access_key    => ENV["AWS_SECRET_ACCESS_KEY"]
  # }

  # fog creds Rackspace Cloud Files example
  # config.fog_credentials {
  #   :provider                 => 'Rackspace',
  #   :rackspace_username  => ENV['RACKSPACE_USERNAME'],
  #   :rackspace_api_key   => ENV['RACKSPACE_API_KEY'],
  #   :rackspace_region    => :dfw
  # }
end
EOF
    end
  end
end
