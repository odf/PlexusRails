Feature: Non-administrator
  A user without the "authorize" privilege should not be able to
  create accounts or assign permissions.

  Background:
    Given a user "staff" exists
    And the user may login, view and edit
    And the user is logged in

  Scenario: An non-administrator cannot create accounts
    When I go to the new user page
    Then I should see "Access denied"

  Scenario: An non-administrator cannot edit other users
    Given a user "client" exists
    When I go to the edit page for user "client"
    Then I should see "Access denied"

  Scenario: An non-administrator cannot assign rights to themself
    When I go to the edit page for user "staff"
    Then I should see "Editing user staff"
    Then I should not see "May login"
