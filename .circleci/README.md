Steps to get items to deploy to Pantheon seem to be:
- [ ] On Pantheon, set up a Pantheon site, called CLNT-bene (where CLNT is the client abbreviation)
- [ ] On Pantheon, log in as your CI bot user (see 1pass).
- [ ] On Pantheon, add the CI bot user email address as a team member to the site.
- [ ] In the repo, give env.dist a TERMINUS_SITE (matching your pantheon site name) and TS_HOST_REPO (matching your pantheon git URL).
- [ ] On Pantheon, as the CI user, under "Machine Tokens" in the account area, create a new Machine token for this project.
- [ ]  In Circle.ci, add the machine token you create as "PANTHEON_TOKEN" to the Circle Environment variables tab:
https://circleci.com/gh/thinkshout/PROJECT-NAME/edit#env-vars
- [ ] On Circle, add the "Pantheon - ThinkShout CI Bot" Private-key to the Circle SSH permissions (found in 1pass): https://circleci.com/gh/thinkshout/PROJECT-NAME/edit#ssh
- [ ] If you wish to deploy a branch to a Multidev on pantheon for ease of testing, you can uncomment out the `-deploy` step
in the config.yml (also in this directory).
