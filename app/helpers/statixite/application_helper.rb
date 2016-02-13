module Statixite
  module ApplicationHelper

    ALERT_TYPES = [:success, :info, :warning, :danger] unless const_defined?(:ALERT_TYPES)

    def bootstrap_flash(options = {})
      flash_messages = []
      flash.each do |type, message|
        # Skip empty messages, e.g. for devise messages set to nothing in a locale file.
        next if message.blank?

        type = type.to_sym
        type = :success if type == :notice
        type = :danger  if type == :alert
        type = :danger  if type == :error
        next unless ALERT_TYPES.include?(type)

        tag_class = options.extract!(:class)[:class]
        tag_options = {
          class: "alert fade in alert-#{type} #{tag_class}"
        }.merge(options)

        close_button = content_tag(:button, raw("&times;"), class: "close", "data-dismiss" => "alert")

        Array(message).each do |msg|
          text = content_tag(:div, close_button + msg.html_safe, tag_options)
          flash_messages << text if msg
        end
      end
      flash_messages.join("\n").html_safe
    end

    def bootstrap_form_flash(obj)
      errors = obj.errors
      return unless obj.errors.any?
      flash_messages = []
      errors.full_messages.each do |message|
        tag_options = {
          class: "alert fade in alert-danger"
        }
        close_button = content_tag(:button, raw("&times;"), class: "close", "data-dismiss" => "alert")
        flash_messages << content_tag(:div, close_button + message, tag_options)
      end
      flash_messages.join("\n").html_safe
    end

    def current_class?(path)
      return 'active' if current_page?(path)
      ''
    end

    def current_parent_class?(obj)
      return 'active' if current_page?(site_path(obj)) || (params[:site_id].present? && obj == Site.find(params[:site_id])) || current_page?(settings_site_path(id: params[:id]))
      ''
    end

    def post_date(post)
      return Date.today if post.new_record?
      return post.front_matter['date'].to_date if post.front_matter['date'].present?
      return post.updated_at.to_date
    end
  end
end
