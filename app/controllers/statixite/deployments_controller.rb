module Statixite
  class DeploymentsController < ApplicationController
    before_action :initialize_site

    def index
      @deployment = Deployment.new
    end

    def create
      GitService.new(@site.site_clone_path, @site.site_remote).clone_or_open
      if @site.update(site_params)
        ds = DeploymentService.new(@site).deploy
        if ds.successful?
          flash[:notice] = "Deployment successful! Please allow for up to 15 minutes for changes to be synced up."
          redirect_to site_deployments_path(@site)
        else
          flash[:alert] = ds.error_message
          redirect_to site_deployments_path(@site)
        end
      else
        @deployment = Deployment.new
        render :index
      end
    end

    def export
      @deployment = @site.deployments.find(params[:deployment_id])
      FileUtils.mkdir_p(Rails.root.join("tmp", "statixite_zips").to_s)
      zip_tmp = Rails.root.join("tmp", "statixite_zips", "#{@site.statixite_name}-#{@deployment.created_at}.zip")
      gs =GitService.new(@site.site_build_path, @site.site_remote).clone_or_open
      begin
        gs.checkout('statixite_build')
        gs.object(@deployment.sha).archive(zip_tmp.to_s, :format => 'zip')
        success = true
      rescue Git::GitExecuteError => e
        Rais.logger.error e
        success = false
      end
      if success
        respond_to do |format|
          format.zip do
            send_file zip_tmp, filename: "#{@site.statixite_name}-#{@deployment.created_at}.zip" 
          end
        end
      else
        flash[:alert] = 'Something went wrong. Please notify support.'
        redirect_to site_deployments_path(@site)
      end
    end

    private

    def initialize_site
      @site = Site.find(params[:site_id])
    end

    def site_params
      params.require(:site).permit(:domain_name)
    end
  end
end
