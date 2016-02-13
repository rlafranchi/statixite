module Statixite
  class SiteOperationService
    attr_reader :status, :error_message

    def initialize(site, options={})
      @site = site
      @branch = options[:branch]
    end

    def build_template
      if @site.valid?
        case @site.build_option
        when 'template'
          if @site.template.nil? || @site.template == 'Jekyll Default'
            build_from_default
          else
            build_from_template
          end
        when 'scratch'
          build_from_scratch
        when 'custom'
          build_from_custom
        else
          @status = :failed
          @error_message = "Invalid Build Option"
          clean_up
        end
      else
        @status = :failed
      end
      self
    end

    def jekyll_build(env='preview')
      case env
        when 'preview'
          options = preview_build_options
        when 'deploy'
          options = site_build_options
      end
      begin
        Jekyll::Commands::Build.process(options)
        @status = :success
      rescue => e
        @status = :failed
        @error_message = e.message
        Rails.logger.error e
      end
      self
    end

    def jekyll_write_config(env='preview')
      preview_hash = @site.settings
      case env
      when 'preview'
        preview_hash["baseurl"] = "/statixite/previews/#{@site.site_name}/"
        preview_hash["url"] = @site.preview_url
      when 'deploy'
        if Statixite.config.deploy_sites_to == :github
          preview_hash["baseurl"] = "/#{@site.github_repo_name}"
        end
        preview_hash["url"] = @site.build_url
      end
      File.open(site_config_with_environment(env), "w+") { |f| YAML.dump(preview_hash, f) }
    end

    def check_and_save_posts_from_file
      written_files = Dir.glob(File.join(@site.site_posts_path, "*"))
      written_files_with_filenames = written_files.map do |file|
        file_basename = File.basename(file).to_s
        content = File.read(file).gsub(/\A---(.|\n)*---\n/, '')
        {
          file: file.to_s,
          filename: file_basename,
          content: content
        }
      end
      saved_posts = @site.posts.map do |post|
        {
          file: post.post_pathname.to_s,
          filename: post.filename,
          content: post.content
        }
      end
      posts_to_delete = saved_posts - written_files_with_filenames
      posts_to_save = written_files_with_filenames - saved_posts
      posts_to_delete.each do |post|
        @site.posts.find_by(filename: post[:filename]).destroy
      end
      posts_to_save.each do |post|
        file = post[:file]
        begin
          front_matter = YAML.load_file(file)
        rescue Psych::SyntaxError => e
          front_matter = {}
          Rails.logger.error e.message
        end
        front_matter = front_matter ? front_matter : {}
        date_matches = /\A\d\d\d\d-\d\d-\d\d/.match(file)
        if date_matches
          front_matter["date"] = date_matches[0]
        elsif front_matter["date"].nil?
          front_matter["date"] = Time.now.strftime('%Y-%m-%d')
        end
        title = front_matter["title"].present? ? front_matter["title"] : File.basename(file, ".*").capitalize
        if front_matter["categories"].present? && front_matter["categories"].is_a?(String)
          front_matter["categories"] = front_matter["categories"].split(" ")
        end
        if front_matter["tags"].present? && front_matter["tags"].is_a?(String)
          front_matter["tags"] = front_matter["tags"].split(" ")
        end
        File.delete(file)
        @site.posts.create(
          title: title,
          front_matter: front_matter,
          content: post[:content],
          filename: post[:filename]
        )
      end
    end

    def successful?
      @status == :success
    end

    private  

    def build_from_custom
      gs_template = GitService.new(@site.site_clone_path, @site.template_repo).clone_or_open
      if @branch.present?
        gs_template.fetch
        gs_template.checkout(@branch)
      end
      gs = GitService.create(@site.site_clone_path, @site.site_remote)
      set_build_status(gs)
    end

    def build_from_default
      gs = GitService.create(@site.site_clone_path, @site.site_remote).make_changes do
        $stdout = StringIO.new('','w')
        Jekyll::Commands::New.process([@site.site_clone_path])
        Rails.logger.info $stdout.string
      end
      set_build_status(gs)
    end

    def build_from_template
      templates = YAML.load_file Statixite::Engine.root.join("lib", "assets", "templates.yaml")
      template = templates.select { |template| template['title'] == @site.template }.first
      repo = template['homepage']
      g = GitService.new(@site.site_clone_path, repo).clone_or_open
      gs = GitService.create(@site.site_clone_path, @site.site_remote, @branch)
      set_build_status(gs)
    end

    def build_from_scratch
      GitService.new(@site.site_clone_path, "https://github.com/statixite/bare.git" ).clone_or_open
      gs = GitService.create(@site.site_clone_path, @site.site_remote)
      set_build_status(gs)
    end

    def set_build_status(gs)
      if gs.successful?
        gs.make_changes do
          jekyll_config_initial
          @site.save
          create_hello_world_posts
        end
        @status = :success
      else
        @status = :failed
        @error_message = gs.error_message
        clean_up
      end
    end

    def clean_up
      SiteDeactivationService.new(@site).deactivate
    end

    def store_settings(config)
      @site.settings.merge!(config)
      @site.settings.merge!(default_site_settings)
    end

    def jekyll_config_initial
      site_config = File.exist?(@site.site_main_config) ? YAML.load_file(@site.site_main_config) : {}
      store_settings(site_config)
      jekyll_write_config
    end

    def site_config_with_environment(env)
      File.join(@site.site_clone_path, "_config_#{env}.yml")
    end

    def default_site_settings
      {
        "title" => @site.site_name.capitalize,
        "description" => 'Your Awesome Website generated by statixite.com! Use the markdown editor to create pages and posts'
      }
    end

    def preview_build_options
      {
        serving: false,
        source: @site.site_clone_path.to_s,
        safe: true,
        quiet: true,
        destination: @site.site_preview_path.to_s,
        config: File.join(@site.site_clone_path, "_config_preview.yml").to_s
      }
    end

    def site_build_options
      {
        serving: false,
        source: @site.site_clone_path.to_s,
        safe: true,
        quiet: true,
        destination: @site.site_build_path.to_s,
        config: File.join(@site.site_clone_path, "_config_deploy.yml").to_s
      }
    end

    def create_hello_world_posts
      @site.posts.create(
        title: 'Echo to Earth',
        front_matter: {
          categories: ['blog']
        },
        content: "Welcome to your first Statixite Blog post.  This post is compiled to pure html, which means no poor server performance and no need for your own database.  You can easily host your site with Statixite or export your site files and use as you please.  Feel free to use a combination of our toolbar helpers, html, and [markdown](http://en.wikipedia.org/wiki/Markdown) to get the most out your blogging power.\nSatixite combines the best ideas of Content Management system with [Jekyll](http://jekyllrb.com), a static website generator.\n\n> Hello.. Hello.. Hello..\n> Is there anybody out there?\n"
      )
      check_and_save_posts_from_file
      update_layouts
    end  

    def update_layouts
      @site.posts.each do |post|
        if post.front_matter['layout'].nil?
          if File.exist?(File.join(@site.site_clone_path, "_layouts", "post.html"))
            layout = "post"
          else
            layout = "default"
          end
          post.front_matter['layout'] = layout
          post.save
        end
      end
    end
  end
end
