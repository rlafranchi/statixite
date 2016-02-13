module Statixite
  class LiquidValidator < ActiveModel::Validator
    def validate(record)
      begin
        Liquid::Template.parse(record.content)
      rescue Liquid::SyntaxError => e
        record.errors[:content] << e.message
      end
    end
  end
end
