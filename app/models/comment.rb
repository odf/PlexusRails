class Comment
  include Mongoid::Document

  field :text, :type => String

  embedded_in :commentable, :inverse_of => :comments
  belongs_to_related :author, :class_name => 'User'

  def on_class
    commentable.class.name if commentable
  end

  def on_id
    commentable.id if commentable
  end

  def allows?(action, user)
    case action.to_sym
    when :view then commentable.allows?(:view, user)
    when :edit then user == author
    else            false
    end
  end
end
