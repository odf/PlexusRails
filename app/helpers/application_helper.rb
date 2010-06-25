module ApplicationHelper
  include Formular::Helper

  def format_text(text)
    sanitize(RedCloth.new(text).to_html)
  end
end
