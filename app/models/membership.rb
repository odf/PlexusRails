class Membership < ActiveRecord::Base
  #field :role, :type => String

  belongs_to :project
  belongs_to :user

  scope :sorted, :order => "memberships.role DESC"
end
