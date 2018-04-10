<?php
/**
 * Custom console commands for the Robo task runner.
 *
 * @see http://robo.li/
 */


class RoboFile extends \ThinkShout\RoboDrupal\Tasks
{

  public function install() {
    if (parent::install()) {
      // Run menu migration.
      // $result = $this->taskExec('drush mi menu_links')
      //   ->run();

      $result = FALSE;

      return $result;
    }
    return FALSE;
  }

  public function devUpdate() {

    $this->_remove('composer.lock');

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
