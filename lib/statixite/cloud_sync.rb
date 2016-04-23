module Statixite
  class CloudSync

    def initialize(site, container_name)
      @fog_client = Fog::Storage.new(Statixite.config.fog_credentials)
      @site = site
      @site_directory = @site.site_build_path
      @container_name = container_name 
      @cloud_directory = @fog_client.directories.find{|d| d.key == @container_name}
      if @cloud_directory.nil?
        @cloud_directory = @fog_client.directories.create :key => @container_name, :public => true
        case Statixite.config.fog_credentials[:provider]
        when 'AWS'
          @fog_client.put_bucket_website(@container_name, IndexDocument: "index.html", ErrorDocument: "404.html")
          @fog_client.put_bucket_policy(@container_name,
            {
              "Statement" => [
                { "Sid"       => "PublicReadGetObject",
                  "Effect"    => "Allow",
                  "Principal" => "*",
                  "Action"    => "s3:GetObject",
                  "Resource"  => "arn:aws:s3:::#{@container_name}/*"
                }
              ]
            }
          )
        when 'Rackspace'
          @cloud_directory.metadata[:web_index] = "index.html"
          @cloud_directory.metadata[:web_error] = "error.html"
        end 
      end
      if @site.hostname.nil? && @cloud_directory.public_url.present?
        case Statixite.config.fog_credentials[:provider]
        when 'AWS'
          @site.hostname = "#{@container_name}.s3-website-#{@fog_client.region}.amazonaws.com"
        when 'Rackspace'
          @site.hostname = URI(@cloud_directory.public_url).host
        end
        @site.save
      end
    end

    def sync
      g = Git.open(@site.site_build_path, :log => Rails.logger)
      g.checkout('statixite_build')
      site_files = Dir.glob(File.join(@site_directory, "**/*")).reject{|f| File.directory?(f) || f.match(File.join(@site_directory, ".git")) }

      site_files_set = Set.new(site_files.collect{|f| f.gsub(/^#{@site_directory}\//,"")})
      site_files_hash = site_files_set.to_a.collect{|f| [f, Digest::MD5.hexdigest(File.read(File.join(@site_directory, f)))]}.inject({}) { |r, s| r.merge!({s[0] => s[1]}) }
  
      cloud_files = Statixite.config.fog_credentials[:provider] == 'Rackspace' ? @cloud_directory.files.reject{|f| f.content_type.include?("/directory")} : @cloud_directory.files

      cloud_files_hash = cloud_files.collect{|f| [f.key, f]}.inject({}) { |r, s| r.merge!({s[0] => s[1]}) }
      cloud_files_set = Set.new(cloud_files_hash.keys)

        
      to_delete_set = cloud_files_set - site_files_set
      to_delete = cloud_files_hash.select { |key,_| to_delete_set.include? key }

      # threaded_run(to_delete, 'destroy')
      to_delete.each do |name, file|
        file.destroy
      end
      to_create = site_files_hash.select { |name, _| !cloud_files_set.include?(name) }

      # threaded_run(to_create, 'create')
      to_create.each do |name, hash|
        @cloud_directory.files.create :key => name, :body => File.open(File.join(@site_directory, name)), :public => true
      end

      
      to_update = site_files_hash.select do |name, md5| 
        cloud_files_set.include?(name) && cloud_files_hash[name].etag != md5
      end

      # threaded_run!(to_update, 'update')
      to_update.each do |name, hash|
        @cloud_directory.files.create :key => name, :body => File.open(File.join(@site_directory, name)), :public => true
      end

      if(to_delete.size + to_create.size + to_update.size > 0)
        Rails.logger.info "------------"
        Rails.logger.info "Changes: "
        Rails.logger.info to_delete_set.to_a.collect{|f| " D #{f}"}.join("\n") if to_delete.size > 0
        Rails.logger.info to_create.collect{|f, _| " A #{f}"}.join("\n") if to_create.size > 0
        Rails.logger.info to_update.collect{|f, _| " M #{f}"}.join("\n") if to_update.size > 0
      end
    end

    private

    # todo improve speed
    def threaded_run!(files, change)
      return if files.empty?
      file_number = 0
      total_files = files.length
      mutex       = Mutex.new
      threads     = []
      5.times do |i|
        threads[i] = Thread.new {
          until files.empty?
            mutex.synchronize do
              file_number += 1
              Thread.current["file_number"] = file_number
            end
            file = files.pop rescue nil
            next unless file
            Rails.logger.info "[#{Thread.current["file_number"]}/#{total_files}] to #{change}..."
            
            case change
            when 'destroy'
            when 'create'
            when 'update'
            end
          end
        }
      end
      threads.each { |t| t.join }
    end
  end
end
