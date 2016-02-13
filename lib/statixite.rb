Gem.loaded_specs['statixite'].dependencies.each do |d|
  require d.name
end

# Carrierwave Config
CarrierWave.configure do |config|
  config.root = Rails.root.to_s
end

require "statixite/engine"
require "statixite/cloud_sync"

module Statixite
end
