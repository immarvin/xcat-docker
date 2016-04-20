#!/bin/bash
branch="master"
[ -n "$BRANCH" ] && branch=$BRANCH
cd /git/xcat-core
git checkout $BRANCH

buildscript="/git/xcat-core/buildcore.sh"
[ "$1" = "-d" ] && buildscript="/git/xcat-core/builddep.sh"
$buildscript 
