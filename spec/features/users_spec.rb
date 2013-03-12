require 'spec_helper'

describe 'With no user' do
  describe 'login' do
    it 'redirects to the new user page' do
      visit login_path

      current_path.should == new_user_path
      page.should have_content('Please create a first user account')
    end
  end
end

describe 'With a user' do
  before(:all) do
    @user = User.make! :login_name => 'olaf', :password => 'geheim'
  end

  after(:all) do
    @user.destroy
  end

  describe 'login' do
    it 'accepts user with a correct name and password' do
      visit login_path
      fill_in 'Login name', :with => 'olaf'
      fill_in 'Password', :with => 'geheim'
      click_button 'Login'

      current_path.should == projects_path
      page.should have_content('Welcome')
    end

    it 'rejects user with a correct name, but incorrect password' do
      visit login_path
      fill_in 'Login name', :with => 'olaf'
      fill_in 'Password', :with => 'secret'
      click_button 'Login'

      current_path.should == login_path
      page.should have_content('Invalid')
    end

    it 'rejects user with an incorrect name' do
      visit login_path
      fill_in 'Login name', :with => 'loaf'
      fill_in 'Password', :with => 'geheim'
      click_button 'Login'

      current_path.should == login_path
      page.should have_content('Invalid')
    end
  end
end
