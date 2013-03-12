require 'spec_helper'

describe 'A user logged in as administrator' do
  before(:all) do
    @admin = User.make!
    @admin.may_login = true
    @admin.may_authorize = true
    @admin.save
  end

  after(:all) do
    @admin.destroy
  end

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
    staff = User.make!
    staff.may_login = true
    staff.may_view = true
    staff.may_edit = true
    staff.save

    visit edit_user_path(staff.id)
    check 'May authorize'
    uncheck 'May edit'
    click_button 'Save'

    staff.reload
    staff.may_login.should be_true
    staff.may_view.should be_true
    staff.may_authorize.should be_true
    staff.may_edit.should be_false
  end
end
