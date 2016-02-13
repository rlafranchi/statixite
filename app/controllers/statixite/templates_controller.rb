module Statixite
  class TemplatesController < ApplicationController
    before_action :initialize_site

    def edit
      respond_to do |format|
        format.json do
          @template = recurse_site(site_path)
          render :json => @template
        end
        format.html
      end
    end

    def update
      if template_params[:path] == ""
        @json = { message: "Something went wrong", status: "error" }
        @response_status = 422
      elsif !sanitized?
        @json = { message: "Invalid name. try #{new_name}", status: "error" }
        @response_status = 422
      elsif (rename_folder? || rename_file?) && rename_not_changed? 
        @json = { message: "#{new_name} not changed.", status: 'info' }
        @response_status = 200
      elsif (new_file? || rename_file?) && new_file_or_folder_exists?
        @json = { message: "File already exists. try another name!", status: "error" }
        @response_status = 422
      elsif (new_folder? || rename_folder?) && new_file_or_folder_exists?
        @json = { message: "Folder already exists. try another name!", status: "warn" }
        @response_status = 422
      elsif new_file? && !new_file_or_folder_exists?
        GitService.new(@site.site_clone_path, @site.site_remote).make_changes do
          File.open(new_file, 'w+') { |f| f.write(template_params[:content]) }
        end
        @json = { message: "#{new_name} created!", status: "success", template: recurse_site(site_path)  }
        @response_status = 201
      elsif new_folder? && !new_file_or_folder_exists?
        GitService.new(@site.site_clone_path, @site.site_remote).make_changes do
          Dir.mkdir(new_file)
        end
        @json = { message: "#{new_name} created!", status: "success", template: recurse_site(site_path) }
        @response_status = 201
      elsif (rename_folder? || rename_file?) && !new_file_or_folder_exists? 
        GitService.new(@site.site_clone_path, @site.site_remote).make_changes do
          File.rename(old_file, new_file)
        end
        @json = { message: "Renamed to #{new_name}", status: 'success', template: recurse_site(site_path) }
        @response_status = 201
      elsif edit_file_content?
        GitService.new(@site.site_clone_path, @site.site_remote).make_changes do
          write_file_content
        end
      else
        @json = { message: 'Something went wrong', status: 'error' }
        @response_status = 422
      end
      apply_post_changes if @response_status.to_s[0] == "2"
      render :json => @json, :status => @response_status
    end

    def upload_files
      if old_file_or_folder_exists? && is_folder?
        GitService.new(@site.site_clone_path, @site.site_remote).make_changes do
          save_uploaded_files
        end
        flash[:notice] = 'Files saved!'
      else
        flash[:alert] =  'Something went wrong, try again.'
      end
      apply_post_changes
      redirect_to site_template_path(@site)
    end

    def destroy
      if Dir.glob(File.join(site_path, "**", "*"), File::FNM_DOTMATCH).delete_if { |a| File.basename(a) == "." }.include? old_file
        FileUtils.rm_rf(old_file, :secure => true)
        flash[:notice] = "#{@site.statixite_name}#{old_path} deleted!"
      else
        flash[:alert] = "Something went wrong, try again"
      end
      apply_post_changes
      redirect_to site_template_path
    end

    private
    
    def save_uploaded_files
      params[:files].each do |file|
        name = sanitize_filename(file.original_filename)
        proposed_file = File.join(old_file, name)
        i = 1
        while File.exist?(proposed_file)
          name = "#{File.basename(proposed_file, '.*')}_#{i}#{Pathname(proposed_file).extname}"
          proposed_file = File.join(old_file, name)
          i += 1
        end
        File.open(File.join(old_file, name), "wb") { |f| f.write(file.tempfile.read) }
      end
    end

    def write_file_content
      file = File.join(site_path, template_params[:path])
      existing_content = File.exist?(file) ? File.read(file) : nil
      begin
        Liquid::Template.parse(template_params[:content])
        File.open(file, 'w+') { |f| f.write(template_params[:content]) }
        @template = recurse_site(site_path)
        @json = { message: "#{new_name} Saved!", status: 'success', template: @template }
        @response_status = 200
      rescue Liquid::SyntaxError, Jekyll::Converters::Scss::SyntaxError => e
        File.open(file, 'w+') { |f| f.write(existing_content) } if existing_content
        @json = { message: e.message, status: 'error' }
        @response_status = 422
        @template = recurse_site(site_path)
      end
    end

    def initialize_site
      @site = Site.find(params[:site_id])
      GitService.new(@site.site_clone_path, @site.site_remote).clone_or_open
      @template = {}
    end

    def recurse_site(path, name=nil)
      file_tree = { new: false, name: (name || @site.statixite_name), root: (name.present? ? false : true), path: path.to_s.gsub(site_path.to_s, '') }
      file_tree[:children] = children = []
      Dir.foreach(path) do |entry|
        next if (entry == '..' || entry == '.' || entry.match("_config_deploy") || entry.match("_config_preview") || entry.split("/").first == '.git' )
        full_path = File.join(path, entry)
        if File.directory?(full_path)
          children << recurse_site(full_path, entry)
        else
          content = File.read(full_path)
          extension = Pathname(entry).extname.gsub('.', '')
          if content.encoding.to_s == "UTF-8" && whitelisted_utf8_extensions.include?(extension)
            children << { editable: true, new: false, name: entry, content: File.read(full_path), extension: extension, path: full_path.gsub(site_path.to_s, '') }
          else
            children << { new: false, name: entry, extension: extension, path: full_path.gsub(site_path.to_s, '') }
          end
        end
      end
      return file_tree
    end

    def site_path
      @site.site_clone_path
    end

    def whitelisted_utf8_extensions
      ['txt', 'html', 'xml', 'yaml', 'yml', 'markdown', 'json', 'mkdown', 'mkdn', 'mkd', 'md', 'css', 'scss', 'less', 'sass', 'js']
    end

    def template_params
      params.require(:template).permit(:content, :path, :name, :extension, :new, :root, :editable)
    end

    def sanitize_filename(filename)
      filename.strip.gsub(/^.*(\\|\/)/, '').gsub(/[^0-9A-Za-z.\-]/, '_')
    end

    def new?
      params[:new].present? && params[:new] == "true"
    end

    def new_file?
      new? && template_params[:content].present? && template_params[:extension].present?
    end

    def new_folder?
      new? && template_params[:content].nil? && template_params[:extension].nil?
    end

    def is_file?
      File.file?(old_file)
    end
   
    def is_folder?
      !File.file?(old_file)
    end

    def old_file_or_folder_exists?
      File.exist?(old_file)
    end

    def new_file_or_folder_exists?
      File.exist?(new_file)
    end

    def rename?
      params[:rename].present? && params[:rename] == "true"
    end

    def rename_file_or_folder?
      rename? && old_file_or_folder_exists?
    end

    def rename_folder?
      rename_file_or_folder? && old_file_or_folder_exists? && is_folder?
    end

    def rename_file?
      rename_file_or_folder? && old_file_or_folder_exists? && is_file?
    end

    def rename_not_changed?
      Pathname(template_params[:path]).basename.to_s == template_params[:name]
    end

    def edit_file_content?
      params[:edit].present? && params[:edit] == "true" && template_params[:content].present? && is_file?
    end

    def sanitized?
      new_name.present? && new_name == template_params[:name]
    end

    def old_path 
      Pathname(template_params[:path])
    end

    def old_file
      File.join(site_path, old_path).to_s
    end

    def new_file
      old_file.gsub(old_path.basename.to_s, template_params[:name])
    end

    def new_name
      template_params[:name].present? ? sanitize_filename(template_params[:name]) : nil
    end
  end
end
