module Statixite
  class Media < ActiveRecord::Base
    mount_uploader :file, FileUploader

    belongs_to :site, :class_name => 'Statixite::Site'
  end
end
