class Comment
  include Mongoid::Document
  include Timestamps

  field :text, :type => String

  embedded_in :commentable, :inverse_of => :comments
  belongs_to_related :author, :class_name => 'User'

  def allows?(action, user)
    case action.to_sym
    when :view then commentable.allows?(:view, user)
    when :edit then user == author
    else            false
    end
  end
end
