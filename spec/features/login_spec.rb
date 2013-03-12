require 'spec_helper'

describe 'Login' do
  describe 'with no user account existing' do
    it 'redirects to the new user page' do
      visit login_path

      current_path.should == new_user_path
      page.should have_content('Please create a first user account')
    end
  end

  describe 'with a user account existing' do
    before(:all) do
      @user = User.make! :login_name => 'olaf', :password => 'geheim'
    end

    after(:all) do
      @user.destroy
    end

    it 'succeeds if a correct name and password are given' do
      visit login_path
      fill_in 'Login name', :with => 'olaf'
      fill_in 'Password', :with => 'geheim'
      click_button 'Login'

      current_path.should == projects_path
      page.should have_content('Welcome')
    end

    it 'fails if a correct name, but incorrect password are given' do
      visit login_path
      fill_in 'Login name', :with => 'olaf'
      fill_in 'Password', :with => 'secret'
      click_button 'Login'

      current_path.should == login_path
      page.should have_content('Invalid')
    end

    it 'fails if an incorrect name is given' do
      visit login_path
      fill_in 'Login name', :with => 'loaf'
      fill_in 'Password', :with => 'geheim'
      click_button 'Login'

      current_path.should == login_path
      page.should have_content('Invalid')
    end
  end
end
