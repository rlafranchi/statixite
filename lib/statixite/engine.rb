module Statixite
  def self.setup(&block)
    @@config ||= Statixite::Engine::Configuration.new
    yield @@config if block
    return @@config
  end

  def self.config
    Rails.application.config
  end

  class Engine < ::Rails::Engine
    isolate_namespace Statixite

    config.generators do |g|
      g.test_framework :rspec
    end

    config.autoload_paths << Statixite::Engine.root.join('app', 'validators')

    config.to_prepare do
      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end
    end

    initializer :assets do |config|
      Rails.application.config.assets.paths << "#{Statixite::Engine.root}/vendor/assets/bower_components"
      Rails.application.config.assets.precompile += %w( jsoneditor/dist/jsoneditor-minimalist.min.js )
      Rails.application.config.assets.precompile += %w( jsoneditor/dist/jsoneditor.css )
      Rails.application.config.assets.precompile += %w( jsoneditor/dist/img/* )
      Rails.application.config.assets.precompile += %w( statixite/*.png statixite/*.gif statixite/*.ico )
      Rails.application.config.assets.precompile += %w( landing-page.css )
      Rails.application.config.assets.precompile += %w( dropzone/dropzone.css )
      Rails.application.config.assets.precompile += %w( dropzone.js )
      Rails.application.config.assets.precompile += %w( statixite/editor.js )
      Rails.application.config.assets.precompile += [ "controllers/statixite/*.js", "controllers/statixite/*.css" ]
      Rails.application.config.assets.precompile += %w( bootstrap/fonts/* )
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
