module Statixite
  class Deployment < ActiveRecord::Base
    belongs_to :site, :class_name => 'Statixite::Site'
  end
end
