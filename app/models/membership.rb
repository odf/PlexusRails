class Membership
  include Mongoid::Document

  field :role, :type => String

  embedded_in :project, :inverse_of => :memberships
  belongs_to_related :user
end
