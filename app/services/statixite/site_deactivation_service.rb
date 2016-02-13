module Statixite
  class SiteDeactivationService
    attr_reader :status, :site
    def initialize(site, options={})
      @site = site
      @options = options
    end

    def deactivate
      FileUtils.rm_rf(@site.site_root_path) if Dir.exist?(@site.site_root_path)
      if site.deployments.any?
        begin
          clean_site
          @site.destroy
          @status = :success
        rescue => e
          @status = :failed
          Rails.logger.error e
        end
      else
        @site.destroy
        @status = :success
      end
      self
    end

    def successful?
      @status == :success
    end
    
    private

    def delete_container
      client = Fog::Storage.new(Statixite.config.fog_credentials)
      begin
        client.delete_multiple_objects(@site.statixite_name, client.get_container(@site.statixite_name).body.map { |val| val["name"] })
        client.delete_container(@site.statixite_name) 
      rescue => e
        Rails.logger.error e
      end
    end

    def clean_site
      case Statixite.config.deploy_sites_to
      when :fog
        delete_container
      when :github
        Excon.delete("https://#{Statixite.config.github_user}:#{Statixite.config.github_token}@api.github.com/repos/#{Statixite.config.github_user}/#{@site.github_repo_name}")      
      end
    end
  end
end
