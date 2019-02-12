<?php

/**
 * Custom console commands for the Robo task runner.
 *
 * @see http://robo.li/
 */
class RoboFile extends \ThinkShout\RoboDrupal\Tasks {

  /**
   * Updates the Bene profile.
   */
  public function devUpdate() {
    $result = $this->taskComposerUpdate()
      ->option('with-dependencies')
      ->arg('drupal/bene')
      ->run();

    if ($result->wasSuccessful()) {
      $this->say('Update complete');
    }

    return $result;
  }

  /**
   * {@inheritdoc}
   */
  public function migrateCleanup($opts = ['migrations' => '']) {
    $migrations = explode(',', $opts['migrations']);
    $project_properties = $this->getProjectProperties();
    foreach ($migrations as $migration) {
      $this->taskExec('drush mrs ' . $migration)->dir($project_properties['web_root'])->run();
    }
    $this->taskExec('drush mr --all && drush pmu bene_migrate_google_sheets -y && drush en bene_migrate_google_sheets -y && drush ms')->dir($project_properties['web_root'])->run();
  }

}
