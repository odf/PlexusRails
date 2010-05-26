Feature: Login
  In order to view and work with restricted data
  As a registered user
  I want to log in

  Scenario Outline: Correct or incorrect login
    Given a user "olaf" exists with password "geheim"
    When I log in as "<login>" with password "<passwd>"
    Then I should be on the <location> page
    And I should see "<message>"

  Examples:
    | login | passwd | message | location |

    | olaf  | geheim | Welcome | projects |
    | olaf  | secret | Invalid | login    |
    | oglaf | geheim | Invalid | login    |


  Scenario: Login redirects to new user page when no user accounts exist
    Given no users exist
    When I go to the login page
    Then I should be on the new user page
    And I should see "Please create a first user account"
