# Included by gitconfig for any repo with an act-security remote: authenticate
# with the work key instead of the personal one in ~/.ssh/config.
[core]
	sshCommand = ssh -F /dev/null -i ~/.ssh/github_act -o IdentitiesOnly=yes
