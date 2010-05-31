Feature: Administrator
  In order to manage access privileges to data
  As a site administrator
  I want to create accounts and assign permissions

  Background:
    Given a user "admin" exists
    And the user may login and authorize
    And the user is logged in

  Scenario: The administrator has access to the "new user" page
    When I go to the new user page
    Then I should see "New User"
    And I should see "May login"

  Scenario: The administrator can create accounts
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

  Scenario: The administrator can assign rights
    Given a user "manager" exists
    And the user may login, view and authorize
    When I go to the user's profile editing page
    And I check "May edit"
    And I uncheck "May authorize"
    And I press "Save"
    Then the user should be allowed to login, view and edit
    But the user should not be allowed to authorize
