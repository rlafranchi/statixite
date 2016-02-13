module Statixite
  class FileUploader < CarrierWave::Uploader::Base
    include CarrierWave::MiniMagick
    storage Statixite.config.carrierwave_storage

    def store_dir
      "sites/#{model.site.site_name}/clone/statixite/uploads/#{model.id}"
    end

    version :thumb do
      process resize_to_fill: [100,100]
    end
  end
end
