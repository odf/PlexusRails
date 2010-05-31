def parse_list(s)
  s.split(/, ?| and /)
end

def login(name, passwd)
  visit logout_path
  visit login_path
  fill_in 'Login name', :with => name
  fill_in 'Password', :with => passwd
  click 'Login'
end

Given /^no users exist$/ do
  User.destroy_all
end

Given /^a user "([a-z0-9.-]+)" exists$/ do |name|
  @user = User.make :login_name => name
end

Given /^a user "([a-z0-9.-]+)" exists with password "(.+)"$/ do |name, passwd|
  @user = User.make :login_name => name, :password => passwd
end

Given /^the user may (.+)$/ do |activities|
  parse_list(activities).each do |name|
    @user.send(User.ability_setter(name), true)
  end
  @user.save
end

Given /^the user is logged in$/ do
  login @user.login_name, @user.password
end

When /^I log in as "(.+)" with password "(.+)"$/ do |user, password|
  login user, password
end

Then /^a user "([a-z0-9.-]+)" should exist$/ do |name|
  (@user = User.where(:login_name => name).first).should_not be_nil
end

Then /^the user should be able to log in with password "(.+)"$/ do |passwd|
  login @user.login_name, passwd
  page.should have_content("Welcome")
end

Then /^the user should be allowed to (.+)$/ do |activities|
  @user = User.where(:login_name => @user.login_name).first
  parse_list(activities).each do |name|
    @user.send(User.ability_getter(name)).should be_true
  end
end

Then /^the user should not be allowed to (.+)$/ do |activities|
  @user = User.where(:login_name => @user.login_name).first
  parse_list(activities).each do |name|
    @user.send(User.ability_getter(name)).should be_false
  end
end
