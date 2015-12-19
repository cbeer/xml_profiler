module ApplicationHelper
  def render_document_field(options = {})
    arr = Array(options[:value]).map do |v|
      content_tag :pre, v
    end

    safe_join arr, ' '
  end
end
