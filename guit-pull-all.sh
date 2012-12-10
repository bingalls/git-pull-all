#!/bin/bash
#guit-pull-all: Graphical frontend to edit ~/.gitrc/WORKSPACEs list of active
#git workspaces
#Then calls git-pull-all, to update these workspaces
#Copyright 2011 bruce.ingalls (at) gmail. Licensed as LGPL version 3

BATCH="git-pull-all.sh";
STYLE="--title=`basename $0` --window-icon=/usr/share/icons/hicolor/48x48/apps/guitflow.png";
WORKSPACE_RC="$HOME/.gitrc/workspaces";

#Find and save list of git workspaces, if it does not already exist
if [ ! -d "$HOME/.gitrc" ]; then
  mkdir "$HOME/.gitrc";
fi

function gui_create() {
  #backup and rename
  if [ -f $WORKSPACE_RC ]; then
    if [ -f "$WORKSPACE_RC.gz" ]; then
      yad $STYLE --text "Click OK, to continue without a backup list"
    fi
    gzip -f $WORKSPACE_RC &
  fi
  if ! which locate ; then
    yad $STYLE --button="gtk-close:1"\
      --text "Missing .git paths in ~/.gitrc/workspaces"\
      --text "Please install updatedb for auto generation";
    return 1;
  fi
  #echo 'Finding .git workspaces. Assuming updatedb is current...'
  #todo: test each dirname segment, to prevent soft links
  for gfile in `locate /.git | egrep '/.git$'`; do
    #-G for effective group; -O for your workspaces
    if [ -G $gfile -o -O $gfile ]; then
      dirname $gfile>>$WORKSPACE_RC;
    fi
  done
  if [ ! -f $WORKSPACE_RC ]; then
    echo -n > $WORKSPACE_RC;
  fi

  gui_edit;   #shouldn't recurse, afaik
}

#$WORKSPACE_RC is a list of git workspaces, with full paths, one per line.
#Allow paths preceded by "#" to be inactive
function gui_edit() {
  if [ ! -f $WORKSPACE_RC ]; then
    gui_create && return 1;
  fi

  #Read list of git workspaces
  sort -u $WORKSPACE_RC --output=$WORKSPACE_RC  #switch to uniq, to add file comments...
  i=0;
  while read line; do
    buffer[$i]=`echo $line|sed 's/^#//'`;
    form[$i]="--field ${buffer[$i]}:CHK";

    if [ `echo $line|egrep '^#'` ]; then
      row[$i]="FALSE";
    else
      row[$i]="TRUE";
    fi
    i=$((i+1));
  done < $WORKSPACE_RC;
  height=$((i*55)) ;

  #Dialog for user editing
  edit=$(yad $STYLE --form --columns=1 --separator=" "\
    --button=Save:0\
    --button=gtk-close:1\
    --button=Create:2\
    --button="No changes":3\
    ${form[*]} ${row[*]})

  case $? in
    3)
      return;;
    2)
      gui_create;
      return;;
    1)
      #Write back changes
      STATUS='Git workspace list successfully updated!';
      j=0;
      echo -n > $WORKSPACE_RC;
      for chk in $edit; do
        if [ $chk == 'TRUE' ]; then
          echo "${buffer[$j]}" >> $WORKSPACE_RC;
        elif [ $chk == 'FALSE' ]; then
          echo "#${buffer[$j]}" >> $WORKSPACE_RC;
        else
          STATUS='Unknown edit command. Some changes were not saved!';
        fi
        j=$((j+1));
      done
      if [ $j -ne $i ]; then
        STATUS="Wrong number of git workspaces edited!\nCheck $WORKSPACE_RC";
      fi
      yad $STYLE --button="gtk-close:1" --text "$STATUS";
      return;;
    *)
      yad $STYLE --button="gtk-close:1" --text "Unknown command!";
      return;;
  esac
}

#Run program
gui_edit;
if which $BATCH >/dev/null 2>&1; then
  results=$($BATCH)
#FIXME: break up $results into multiple lines, or use a progress bar
  echo $results;
  yad $STYLE --button="gtk-close:1" --text "`head $results`";
else
  yad $STYLE --button="gtk-close:1" --text "Please install $BATCH into PATH";
fi

