module Statixite
  class MediaController < ApplicationController
    before_action :initialize_site, :except => [:show]

    def index
      @media_index = @site.media.order(:created_at => "DESC").page(params[:page]).per(6)
      @media = Media.new

      respond_to do |format|
        format.js
        format.html
        format.json { render :json => @media_index }
      end
    end

    def show
      @media = Media.find(params[:id])
      content_type = MIME::Types.type_for(@media.file.path).first.content_type
      file = params[:file_name].include?("thumb") ? @media.file.thumb.path : @media.file.path
      send_file file, :type => content_type, :disposition => :inline
    end

    def create
      @media = @site.media.new(file: params[:file])
      if @media.valid?
        gs = GitService.new(@site.site_clone_path, @site.site_remote).make_changes do
          @media.save
        end
        status = 200
        response = { message: "success", media: @media }
      else
        status = 400
        response = { error: @media.errors.full_messages.join(',') }
      end
      respond_to do |format|
        format.json{ render :json => response, :status => status }
      end
    end

    def destroy
      @media = @site.media.find(params[:id])
      if @media.destroy
        flash[:notice] = 'Image deleted'
        redirect_to :action => :index
      else
        flash[:alert] = 'Something went wrong'
        redirect_to :action => :index
      end
    end

    private

    def initialize_site
      @site = Site.find(params[:site_id])
    end

    def media_params
      params.require(:media).permit(:file)
    end
  end
end
