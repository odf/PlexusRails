# These helper methods can be called in templates to set variables to be used in
# the layout.
module LayoutHelper
  def title(page_title, show_title = true)
    content_for(:title) { h(page_title.to_s) }
    @show_title = show_title
  end
  
  def show_title?
    @show_title
  end
  
  def strip_html(text)
    text.gsub(/<\/?[^>]*>/, "").gsub(/&[^;]*;/, "")
  end
end
