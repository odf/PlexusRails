Feature: Administrator
  In order to manage access privileges to data
  As a site administrator
  I want to create accounts and assign permissions

  Background:
    Given a user "admin" exists
    And the user may login and authorize
    And the user is logged in

  Scenario: An administrator can create accounts
    When I go to the new user page
    And I fill in the following:
      |Login name       |testuser             |
      |First name       |Hans                 |
      |Last name        |Wurscht              |
      |Email            |hans.wurscht@mail.com|
      |Password         |secret               |
      |Confirm password |secret               |
    And I press "Save"
    Then I should see "User was successfully created"
    And a user "testuser" should exist
    And the user should be able to log in with password "secret"

  @focus
  Scenario: An administrator can assign rights to other users
    Given a user "staff" exists
    And the user may login, view and edit
    When I go to the edit page for user "staff"
    And I check "May authorize"
    And I uncheck "May edit"
    And I press "Save"
    Then the user should be allowed to login, view and authorize
    But the user should not be allowed to edit

  Scenario: An administrator cannot assign rights to themself
    When I go to the edit page for user "admin"
    Then I should not see "May login"
