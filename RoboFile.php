<?php
/**
 * Custom console commands for the Robo task runner.
 *
 * @see http://robo.li/
 */


class RoboFile extends \ThinkShout\RoboDrupal\Tasks
{


  public function devUpdate() {

    $this->taskComposerUpdate()
      ->option('with-dependencies')
      ->arg('drupal/bene')
      ->run();

    // Run the installation.
    $result = $this->taskExec('drush cim --partial')
      ->run();

    if ($result->wasSuccessful()) {
      $this->say('Install complete');
    }

    return $result;
  }
}
