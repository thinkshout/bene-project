<?php

use Behat\Behat\Context\Context;
use Behat\Behat\Context\SnippetAcceptingContext;
use Drupal\DrupalExtension\Context\RawDrupalContext;

/**
 * Define application features from the specific context.
 */
class FeatureContext extends RawDrupalContext implements Context, SnippetAcceptingContext {
  const DEFAULT_PASSWORD = "admin";

  /**
   * @var int
   *   The ID of the student currently being used by a test.
   */
  private $current_student_id;

  /**
   * Initializes context.
   * Every scenario gets its own context object.
   *
   * @param array $parameters
   *   Context parameters (set them in behat.yml)
   */
  public function __construct(array $parameters = []) {
    // Initialize your context here
  }

  /**
   * @AfterScenario @migration
   */
  public function afterScenario(\Behat\Behat\Hook\Scope\AfterScenarioScope $scope) {
    $driver = $this->getDriver('drush');
    $driver->mr('--all');
  }

  /**
   * Checks that access was denied for a page based on either status code or
   * "Access Denied." in the error message.
   *
   * @Then I should get an access denied error
   */
  public function assertAccessDenied() {
    $status_code = $this->getSession()->getStatusCode();
    if ($status_code != 403) {
      // Look for the error message div.
      $errorNode = $this->getSession()
        ->getPage()
        ->find('css', '.messages--error');
      if ($errorNode) {
        if (strpos($errorNode->getText(), 'Access denied.') === FALSE) {
          throw new Exception("No access denied message displayed.");
        }
      }
      else {
        throw new Exception("No error message displayed.");
      }
    }
  }
}
