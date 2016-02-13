$:.push File.expand_path("../lib", __FILE__)
require "statixite/version"

Gem::Specification.new do |s|
  s.name        = "statixite"
  s.version     = Statixite::VERSION
  s.authors     = ["Richard LaFranchi"]
  s.email       = ["rlafranchi@icloud.com"]
  s.homepage    = "https://github.com/rlafranchi/statixite"
  s.summary     = "A Management Tool for Static Websites"
  s.description = "Statixite allows you to easily manage multiple static websites.  It is a mix of a content management solution as well as a deployment solution.  It allows you to configure various deployment options such as S3, Rackspace, or Github Pages."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib,vendor}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2"
  s.add_dependency "uglifier", "~> 2.7"
  s.add_dependency "haml-rails", "~> 0.9"
  s.add_dependency "therubyracer", "~> 0.12"
  s.add_dependency "jquery-rails", "~> 4.1"
  s.add_dependency "less-rails", "~> 2.7"
  s.add_dependency "bootstrap_form", "~> 2.3"
  s.add_dependency "fog", "~> 1.37"
  s.add_dependency "carrierwave", "~> 0.10"
  s.add_dependency "dropzonejs-rails", "~> 0.7"
  s.add_dependency "mini_magick", "~> 4.3"
  s.add_dependency "jekyll", "~> 3.0"
  s.add_dependency "jekyll-sitemap", "~> 0.9"
  s.add_dependency "jekyll-paginate", "~> 1.1"
  s.add_dependency "jekyll-feed", "~> 0.4"
  s.add_dependency "jekyll-archives", "~> 2.1"
  s.add_dependency "jekyll-contentblocks", "~> 1.1"
  s.add_dependency "redcarpet", "~> 3.3"
  s.add_dependency "pygments.rb", "~> 0.6"
  s.add_dependency "rdiscount", "~> 2.1"
  s.add_dependency "git", "~> 1.2"
  s.add_dependency "validates_hostname", "~> 1.0"
  s.add_dependency "kaminari", "~> 0.16"
  s.add_dependency "htauth", "~> 2.0"
  s.add_dependency "git_clone_url", "~> 2.0"

  s.add_development_dependency "pg"
end
