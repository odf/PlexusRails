require 'machinist/active_record'
require 'ffaker'

User.blueprint do
  login_name             { Faker::Name.first_name }
  password { (1..10).map { ('a'..'z').to_a.sample}.join }
  password_confirmation  { object.password }
  first_name             { Faker::Name.first_name }
  last_name              { Faker::Name.last_name }
  email                  { Faker::Internet.email }
end

Project.blueprint do
  name                   { Faker::Company.name }
end
