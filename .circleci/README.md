Steps to get items to deploy to Pantheon seem to be:
- [ ] On Pantheon, set up a Pantheon site.
- [ ] On Pantheon, log in as your CI bot user.
- [ ] On Pantheon, add the CI bot user email address as a team member to the site.
- [ ] In the repo, give env.dist a TERMINUS_SITE and TS_HOST_REPO.
- [ ]  In Circle.ci, add the PANTHEON_TOKEN associated with the CI bot to the Circle Environment variables tab:
https://circleci.com/gh/thinkshout/PROJECT-NAME/edit#env-vars
- [ ] On Circle, add the "Pantheon - ThinkShout CI Bot" Private-key to the Circle SSH permissions: https://circleci.com/gh/thinkshout/PROJECT-NAME/edit#ssh
- [ ] If you wish to deploy a branch to a Multidev on pantheon for eas of testing, you can uncomment out the `-deploy` step
in the config.yml (also in this directory).
