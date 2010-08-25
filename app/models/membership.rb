class Membership < ActiveRecord::Base
  # t.string  "role"

  belongs_to :project
  belongs_to :user

  scope :sorted, :order => "memberships.role DESC"
end
