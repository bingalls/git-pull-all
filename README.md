# Updates all your Git repos
* guit-pull-all.sh is a graphical front-end to edit the ~/.gitrc/workspaces
file, then call git-pull-all.sh. Requires Gnome/Linux Yad package
* git-pull-all.sh can be used alone, for console use, such as OSX or Cygwin

Uses locatedb to save all git workspaces into ~/.gitrc/workspaces, if it
does not exist.

Calls `git pull` on each workspace in ~/.gitrc/workspaces
