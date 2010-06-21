class Membership
  include Mongoid::Document

  field :role, :type => String

  embedded_in :project, :inverse_of => :memberships
  belongs_to_related :user

  named_scope :sorted, :order_by => [[:role, :desc]]
end
