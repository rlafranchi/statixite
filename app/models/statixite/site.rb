module Statixite
  class Site < ActiveRecord::Base
    has_many :posts, :dependent => :destroy, :class_name => 'Statixite::Post'
    has_many :deployments, :dependent => :destroy, :class_name => 'Statixite::Deployment'
    has_many :media, :class_name => 'Statixite::Media'

    SLUG_FORMAT = /[a-z0-9]+(?:-[a-z0-9]+)*/
    REPO_FORMAT = /((git|ssh|http(s)?)|(git@[\w\.]+))(:(\/\/)?)([\w\.@\:\/\-~]+)(\.git)(\/)?/
    validates_presence_of :site_name
    validates_uniqueness_of :site_name
    validates_length_of :site_name, :maximum => 50
    validates_format_of :site_name, :with => Regexp.new('\A' + SLUG_FORMAT.source + '\z')
    validates_format_of :template_repo, :with => Regexp.new('\A' + REPO_FORMAT.source + '\z'), :message => "Please enter a valid url for a git repository", :on => :create, :if => :custom_build_option?
    
    include ActiveModel::Validations
    validates :domain_name, :hostname => true, :allow_blank => true

    def statixite_name
      site_name
    end

    def preview_url
      "/statixite/previews/#{site_name}"
    end

    def build_url
      if domain_name.present?
        "http://#{domain_name}"
      else
        settings["url"]
      end
    end

    def github_repo_name
      "statixite-#{site_name}"
    end

    def site_root_path
      File.join(sites_path, site_name)
    end

    def site_clone_path
      File.join(site_root_path, "clone")
    end

    def site_posts_path
      File.join(site_clone_path, "_posts")
    end

    def site_build_path
      File.join(site_root_path, "build")
    end

    def site_preview_path
      File.join(Rails.public_path, "statixite", "previews", site_name)
    end

    def site_remote
      File.join(site_root_path, "repo")
    end

    def site_main_config
      File.join(site_clone_path, "_config.yml")
    end

    private

    def sites_path
      Rails.root.join("sites").to_s
    end

    def custom_build_option?
      self.build_option == 'custom'
    end
  end
end
