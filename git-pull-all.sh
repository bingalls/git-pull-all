#!/bin/bash
#Easy way to update all your git work
#Todo: provide option to rebuild ~/.gitrc/workspaces
#Todo: exploit alternatives, including slocate, beagle, spotlight, etc.

if [ $# -gt 0 ]; then    #Any args bring up help
   echo "Usage: `basename $0`"
   echo 'Pulls updates to all branches of all git workspaces you own'
   echo 'Calls locate to write all your Git workspace paths to ~/.gitrc/workspaces'
   echo 'Comment out with "#" those that you do not update'
   echo 'You must add new git workspaces to this file'
   echo 'You should run updatedb before the first time you run this'
   exit 0
fi

#Pull from each git branch
git_pull_branches() {
   for branch in `git branch|cut -d'*' -f2|awk '{print $1}'`; do
       if git checkout $branch ; then
           #git fetch origin $1|grep diverged    #Test fetch again, to prevent merge?
           git pull origin $branch
       else
           return 1    #grep for: "error: You have local changes to '.*'; cannot switch branches."
       fi
   done
}

#Jump to each .git workspace. Iterate for each git branch
update_current_path() {
   CurrBranch=`git status|grep '# On branch'|awk '{print $4}'`    #remember original branch

   if ! git fetch origin ;    then
       echo "Problem fetching repo origin(s) for $PWD. Check network, then git admin"
       return 2
   fi

   if ! git status|grep 'nothing to commit (working directory clean)' > /dev/null
   then
       if ! git status|grep 'no changes added to commit (use "git add" and/or "git commit -a")' > /dev/null
       then
           echo "`basename $0`: commit your work in $PWD, and run again"
           return 3
       else
           echo "Continuing; check commits in $PWD"
       fi
   fi
   git_pull_branches;
   git checkout $CurrBranch;    #restore original branch
}

#Find and save list of git workspaces, if it does not already exist
if [ ! -d "$HOME/.gitrc" ]; then
   mkdir "$HOME/.gitrc"
fi
if [ ! -f "$HOME/.gitrc/workspaces" ]; then
   if ! which locate ; then
       echo 'Please install locate, else add each .git path to ~/.gitrc/workspaces'
       return 4
   fi
   echo 'Finding .git workspaces. Assuming updatedb is current...'
   #todo: test each dirname segment, to prevent soft links
   for gfile in `locate /.git | egrep '/.git$'`; do
       #Add -G for workspaces your group owns
       if [ -O $gfile ]; then
           dirname $gfile>>"$HOME/.gitrc/workspaces"
       fi
   done
fi

#Iterate for every .git workspace in ~/.gitrc/workspaces
while read workspace; do
   if echo $workspace|egrep -v '^\s*#.+$' > /dev/null ; then #skip comments
       cd $workspace
       update_current_path;
   fi
done < "$HOME/.gitrc/workspaces"
