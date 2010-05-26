Given /^a user "([a-z0-9.-]+)" exists with password "(.+)"$/ do |name, passwd|
  User.make :login_name => name, :password => passwd
end

When /^I log in as "(.+)" with password "(.+)"$/ do |user, password|
  visit login_path
  fill_in 'Login name', :with => user
  fill_in 'Password', :with => password
  click 'Login'
end
