class Comment < ActiveRecord::Base
  include Blame

  #field :text, :type => String

  belongs_to :author, :class_name => 'User'
  belongs_to :commentable, :polymorphic => true

  def allows?(action, user)
    case action.to_sym
    when :view then commentable.allows?(:view, user)
    when :edit then user == author
    else            false
    end
  end
end
