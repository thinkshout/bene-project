<?php

/**
 * @file
 * Fixes the profile path for Bene, which is required for old sites.
 */

$state = \Drupal::state()->get('system.profile.files');

$state['bene'] = 'profiles/contrib/bene/bene.info.yml';

\Drupal::state()->set('system.profile.files', $state);
