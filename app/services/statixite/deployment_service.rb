module Statixite
  class DeploymentService
    attr_reader :error_message, :directory

    def initialize(site)
      @site = site
    end

    def deploy
      gs = GitService.new(@site.site_build_path, @site.site_remote)
      if gs.successful?
        begin
          git_info_from_build = build_deploy_branch(gs)
          perform_deploy
          deployment = @site.deployments.create(
            :version => git_info_from_build[0],
            :sha => git_info_from_build[1]
          )
          @status = :success
        rescue => e
          Rails.logger.error e
          @error_message = e.message
          @status = :failed
        end
      else
        @error_message = gs.error_message
        @status = :failed
      end
      self
    end

    def successful?
      @status == :success
    end

    private

    def perform_deploy
      case Statixite.config.deploy_sites_to
      when :local
      when :github
        create_repo
      when :fog
        Statixite::CloudSync.new(@site, "statixite-#{@site.site_name}-#{@site.id}").sync
      else
      end
    end

    def build_deploy_branch(gs)
      gs.build_branch
      sos = SiteOperationService.new(@site)
      sos.jekyll_write_config('deploy')
      sos.check_and_save_posts_from_file
      sos.jekyll_build('deploy')
      gs.build_deploy(next_version)
    end

    def next_version
      ((@site.deployments.count + 1).to_f / 10).round(1)
    end

    def create_repo
      g = GitService.new(@site.site_build_path, @site.site_remote).clone_or_open
      if @site.deployments.empty?
        response = Excon.post("https://#{Statixite.config.github_user}:#{Statixite.config.github_token}@api.github.com/user/repos", :body => { :name => @site.github_repo_name }.to_json )      
        g.add_remote("github", JSON.parse(response.body)["ssh_url"])
      end
      g.branch("gh-pages").checkout
      g.branch("gh-pages").merge("statixite_build")
      g.push(g.remote("github"), 'gh-pages', { :tags => true })
    end
  end
end
