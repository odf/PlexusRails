Given /^a user "([a-z0-9.-]+)" exists with password "(.+)"$/ do |name, passwd|
  u = User.new(:password => passwd, :password_confirmation => passwd,
               :first_name => Sham.first_name,
               :last_name => Sham.last_name,
               :email => Sham.email)
  u.login_name = name
  u.save!
end

When /^I log in as "(.+)" with password "(.+)"$/ do |user, password|
  visit login_path
  fill_in 'Login name', :with => user
  fill_in 'Password', :with => password
  click 'Login'
end
