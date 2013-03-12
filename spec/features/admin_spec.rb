require 'spec_helper'

describe 'A user' do
  before(:each) do
    User.destroy_all

    @admin = User.make
    @admin.may_login = true
    @admin.may_authorize = true
    @admin.save

    @staff = User.make
    @staff.may_login = true
    @staff.may_view = true
    @staff.may_edit = true
    @staff.save

    @client = User.make!
  end

  after(:each) do
    User.destroy_all
  end

  describe 'logged in as administrator' do
    before(:each) do
      visit login_path
      fill_in 'Login name', :with => @admin.login_name
      fill_in 'Password', :with => @admin.password
      click_button 'Login'
    end

    after(:each) do
      visit logout_path
    end

    it 'can create an account' do
      visit new_user_path

      { 'Login name'       => 'testuser',
        'First name'       => 'Hans',
        'Last name'        => 'Wurscht',
        'Email'            => 'hans.wurscht@mail.com',
        'Password'         => 'secret',
        'Confirm password' => 'secret'

      }.each do |key, value|
        fill_in key, :with => value
      end
      click_button 'Save'

      page.should have_content('User was successfully created')
      User.where(:login_name => 'testuser').first.should_not be_nil
    end

    it 'can assign rights to other users' do
      visit edit_user_path(@staff.id)
      check 'May authorize'
      uncheck 'May edit'
      click_button 'Save'

      @staff.reload
      @staff.may_login.should be_true
      @staff.may_view.should be_true
      @staff.may_authorize.should be_true
      @staff.may_edit.should be_false
    end

    it 'can not assign rights to themselves' do
      visit edit_user_path(@admin.id)

      page.should_not have_content('May login')
    end
  end

  describe 'logged in as non-administrator' do
    before(:each) do
      visit login_path
      fill_in 'Login name', :with => @staff.login_name
      fill_in 'Password', :with => @staff.password
      click_button 'Login'
    end

    after(:each) do
      visit logout_path
    end

    it 'cannot create an account' do
      visit new_user_path

      page.should have_content('Access denied')
      page.should_not have_content('Login name')
    end

    it 'cannot edit other users' do
      visit edit_user_path(@client.id)

      page.should have_content('Access denied')
      page.should_not have_content('Login name')
    end

    it 'can not assign rights to themselves' do
      visit edit_user_path(@staff.id)

      page.should have_content('Editing user ' + @staff.login_name)
      page.should_not have_content('May login')
    end
  end
end
