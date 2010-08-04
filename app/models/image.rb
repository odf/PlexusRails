class Image
  include Mongoid::Document
  include Timestamps

  embedded_in :illustratable, :inverse_of => :image

  def allows?(action, user)
    commentable.allows?(action, user)
  end
end
