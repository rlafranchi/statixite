module Statixite
  class JekyllTemplateValidator < ActiveModel::Validator
    def validate(record)
      begin
        if record.build_option == 'custom'
          Timeout::timeout(30) {
            Git.ls_remote(record.template_repo)
          }
        end
      rescue StandardError => e
        Rails.logger.error e
        record.errors[:template_repo] << "Can't read from remote"
      end
    end
  end
end
