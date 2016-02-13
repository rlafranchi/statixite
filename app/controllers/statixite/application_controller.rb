module Statixite
  class ApplicationController < ActionController::Base
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :exception
    layout "statixite/dashboard"

    private

    def apply_post_changes
      GitService.new(@site.site_clone_path, @site.site_remote).make_changes do
        SiteOperationService.new(@site).check_and_save_posts_from_file
      end
    end
    
    def apply_config_changes
      GitService.new(@site.site_clone_path, @site.site_remote).make_changes do
        SiteOperationService.new(@site).jekyll_write_config
      end
    end
  end
end
