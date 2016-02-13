module Statixite
  class SitesController < ApplicationController

    def new
      @site = Site.new
      @templates = YAML.load_file Statixite::Engine.root.join("lib", "assets", "templates.yaml")
      @templates = @templates.select { |template| template["whitelisted"].present? && template["whitelisted"] == true }
    end

    def repo_branches
      @site = Site.new(template_repo: params[:repo])
      @site.build_option = 'custom'
      @site.valid?
      if params[:repo].present? && params[:repo].is_a?(String) && @site.errors[:template_repo].blank?
        begin
          status = Timeout::timeout(20) {
            g = Git.ls_remote(params[:repo])
            @data = g["branches"].keys
            @message = "Repo Found, please choose a branch to initialize the new repository with."
          } 
        rescue Git::GitExecuteError, Timeout::Error => e
          @data = []
          @message = "Git Repository not found"
          @status = 404
        end
      else
        @data = []
        @message = "Git Repository not found"
        @status = 404
      end
      respond_to do |format|
        format.json { render :json => { message: @message, data: @data, status: (@status == 404 ? 'error' : 'success') }, :status => @status }
      end
    end

    def build_and_preview
      @site = Site.find(params[:id])
      build_preview
    end

    def create
      @site = Site.new(site_params)
      result = SiteOperationService.new(@site, { :branch => params[:repo_branch] }).build_template
      if result.successful?
        flash[:success] = "#{@site.statixite_name} saved."
        redirect_to sites_path
      else
        @templates = YAML.load_file Statixite::Engine.root.join("lib", "assets", "templates.yaml")
        @templates = @templates.select { |template| template["whitelisted"].present? && template["whitelisted"] == true }
        if result.error_message.present?
          flash.now[:alert] = result.error_message
        end
        render :new
      end
    end

    def index
      @sites = Site.all.order(:site_name).page params[:page]
    end

    def settings
      @site = Site.find(params[:id])
      @settings = @site.settings
      respond_to do |format|
        format.html
        format.json { render :json => @settings }
      end
    end

    def update
      @site = Site.find(params[:id])
      @site.settings = params[:site][:settings]
      @site.domain_name = params[:site][:domain_name]
      if @site.save
        apply_config_changes
        respond_to do |format|
          format.json { render :json => @site.to_json }
        end
      else
        respond_to do |format|
          format.json { render :json => { :errors => @site.errors }, :status => :unprocessible_entity }
        end
      end
    end

    def destroy
      @site = Site.find(params[:id])
      if SiteDeactivationService.new(@site).deactivate.successful?
        flash[:notice] = "Site Removed!"
      else
        flash[:notice] = "Something went wrong."
      end
      redirect_to sites_path
    end

    def preview_credentials
      @site = Site.find(params[:id])
      HTAuth::PasswdFile.open(auth_file, HTAuth::File::CREATE) do |pf|
        pf.add_or_update(params[:login], params[:password])
      end
      flash.now[:notice] = "Credentials Saved"
      render :build_and_preview
    end

    private

    def build_preview
      result = SiteOperationService.new(@site)
      GitService.new(@site.site_clone_path, @site.site_remote).make_changes do
        result.jekyll_write_config
        result.check_and_save_posts_from_file
      end
      result.jekyll_build
      if result.successful?
        unless File.exist?(auth_file)
          @password = generate_pw(10)
          HTAuth::PasswdFile.open(auth_file, HTAuth::File::CREATE) do |pf|
            pf.add_or_update(@site.site_name, @password)
          end
        end
        flash[:notice] = "Preview built!"
      else
        flash[:alert] = result.error_message
        redirect_to site_template_path(@site)
      end
    end

    def auth_file
      File.join(@site.site_root_path, "#{@site.site_name}.htpasswd")
    end

    def site_params
      params.require(:site).permit(:site_name, :template, :settings, :build_option, :template_repo, :domain_name)
    end

    def generate_pw(number)
      charset = Array('A'..'Z') + Array('a'..'z') + Array(0..9)
      Array.new(number) { charset.sample }.join
    end
  end
end
