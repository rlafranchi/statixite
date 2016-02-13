module Statixite
  class PostsController < ApplicationController
    before_action :initialize_site

    def index
      @posts = @site.posts.order(:created_at => "DESC").page params[:page]
    end

    def show
      @post = @site.posts.find(params[:id])
      respond_to do |format|
        format.json { render :json => @post }
      end
    end

    def new
      @post = Post.new
      @media = Media.new
      @media_index = @site.media.order(:created_at => "DESC").page(1).per(6)
    end

    def create
      @post = @site.posts.new(post_params)
      @post.front_matter = params[:post][:front_matter]
      if @post.save
        apply_post_changes
        respond_to do |format|
          format.json { render :json => @post }
        end
      else
        respond_to do |format|
          format.json { render :json => { :errors => @post.errors }, :status => :unprocessible_entity }
        end
      end
    end

    def edit
      @post = @site.posts.find(params[:id])
      @media = Media.new
      @media_index = @site.media.order(:created_at => "DESC").page(1).per(6)
    end

    def update
      @post = @site.posts.find(params[:id])
      @post.front_matter = params[:post][:front_matter]
      if @post.update(post_params)
        apply_post_changes
        respond_to do |format|
          format.json { render :json => @post }
        end
      else
        respond_to do |format|
          format.json { render :json => { :errors => @post.errors }, :status => :unprocessible_entity }
        end
      end
    end

    private

    def post_params
      params.require(:post).permit(:title, :content)
    end

    def initialize_site
      @site = Site.find(params[:site_id])
    end
  end
end
