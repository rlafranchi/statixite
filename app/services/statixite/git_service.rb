module Statixite
  class GitService
    attr_reader :local_path, :remote, :remote_name, :local_parent, :error_message

    def initialize(local_path, remote, status = nil)
      @local_path = local_path
      @remote = remote
      @remote_name = File.basename(local_path)
      @local_parent = File.expand_path("..", local_path)
      begin
        Git.ls_remote(@remote)
        @status = :success
      rescue Git::GitExecuteError => e
        @status = :failed
        @error_message = e.message
      end
    end

    def clone_or_open
      if successful?
        Git.clone(remote, remote_name, :path => local_parent) unless Dir.exist?(local_path)
        Git.open(local_path, :log => Logger.new("/dev/null") )
      end
    end

    def self.create(local_path, remote, options={})
      FileUtils.mkdir_p(local_path)
      git_path = File.join(local_path, ".git")
      FileUtils.rm_rf(git_path) if Dir.exist?(git_path)
      File.open(File.join(local_path, ".gitignore"), 'a') do |f|
        f << "\n_config_preview.yml\n_config_deploy.yml"
      end
      FileUtils.mkdir_p(remote)
      Git.init(remote, :bare => true)
      g = Git.init(local_path)
      g.add_remote('origin', remote)
      g.config('user.name', 'Statixite')
      g.config('user.email', 'git@git.statixite.com')
      g.add(:all => true)
      g.commit('Initial')
      begin
        g.push
        new(local_path, remote)
      rescue Git::GitExecuteError => e
        Rails.logger.error e
        new(local_path, nil)
      end
    end

    def make_changes(&block)
      if successful?
        begin
          g = clone_or_open
          g.checkout('master')
          g.pull
          yield
          g.add(:all => true)
          g.commit('Auto commit', :allow_empty => true)
          g.push
        rescue Git::GitExecuteError => e
          @status = :failed
          @error_message = e.message
        end
      end
      self
    end

    def build_branch
      g = clone_or_open
      unless g.branches.remote.map(&:name).include?("statixite_build")
        g.branch('statixite_build').checkout
        g.remove('.', {:recursive => true})
        g.add(:all => true)
        g.commit("Initial", :allow_empty => true)
        g.push('origin', 'statixite_build')
      end
      g.checkout('statixite_build')
      g.pull('origin', 'statixite_build')
    end

    def build_deploy(next_version)
      g = clone_or_open
      g.add(:all => true)
      g.commit("Deployment for #{@remote_name}", :allow_empty => true)
      version_to_try = next_version
      begin
        g.add_tag("v#{version_to_try}")
      rescue Git::GitExecuteError => e
        Rails.logger.info "v#{version_to_try} exists retrying"
        version_to_try = (version_to_try + 0.1).round(1)
        retry
      end
      g.commit("Release tag created #{@remote_name}: v#{version_to_try}", :allow_empty => true)
      g.push('origin', 'statixite_build')
      [version_to_try, g.tags.last.sha]
    end

    def successful?
      @status == :success
    end
  end
end
