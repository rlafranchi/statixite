module Statixite
  class Post < ActiveRecord::Base
    belongs_to :site, :class_name => 'Statixite::Site'
    validates_presence_of :title

    before_save :save_layout_and_title
    before_create :write_slug
    after_create :write_to_tmp
    before_update :check_title_change
    after_update :write_to_tmp

    include ActiveModel::Validations
    validates_with LiquidValidator

    def write_to_tmp(env='preview')
      FileUtils.mkdir_p(site.site_posts_path)
      write_content
    end

    def post_pathname
      Rails.root.join(site.site_posts_path, self.filename)
    end

    def write_slug
      self.slug = append_suffix(self.title.parameterize)
    end

    private

    def post_date
      return Time.now if front_matter.nil?
      front_matter['date'].present? ? front_matter['date'].to_time : Time.now
    end

    def proposed_post_pathname(str)
      File.join(site.site_posts_path, post_date.strftime("%Y-%m-%d-#{str}.markdown"))
    end

    def append_suffix(str, i=0)
      self.filename = File.basename(proposed_post_pathname(str)).to_s
      return str unless File.exist?(proposed_post_pathname(str))
      i += 1
      str = i == 1 ? str << "-#{i}" : str.gsub(/\-#{i-1}\z/, "-#{i}")
      append_suffix(str, i)
    end

    def write_content
      new_contents = "#{front_matter.to_yaml}---\n" << content.to_s
      File.open(post_pathname, 'w') do |f|
        f.write(new_contents)
      end
    end

    def check_title_change
      if changed.include?("title")
        write_slug
      end
      if changed.include?("filename")
        File.delete(File.join(site.site_posts_path, changes[:filename][0]))
      end
    end

    def save_layout_and_title
      front_matter['title'] = title
      front_matter['layout'] = check_for_layout
    end

    def check_for_layout
      if File.exist?(File.join(site.site_clone_path, "_layouts", "post.html"))
        "post"
      else  
        "default"
      end
    end
  end
end
