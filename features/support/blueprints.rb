require 'machinist/active_record'
require 'sham'
require 'faker'

Before { Sham.reset } # reset Shams in between scenarios

Sham.login_name { Faker::Name.first_name }
Sham.password   { (1..10).map { ('a'..'z').to_a.rand}.join }
Sham.first_name { Faker::Name.first_name }
Sham.last_name  { Faker::Name.last_name }
Sham.email      { Faker::Internet.email }

User.blueprint do
  login_name
  password
  password_confirmation { self.password }
  first_name
  last_name
  email
end

Sham.name           { Faker::Company.name }

Project.blueprint do
  name
end
