#!/bin/bash

set -e

echo "${TRAVIS_PULL_REQUEST}"
echo "${TRAVIS_EVENT_TYPE}"

git clone "https://${GH_REF}" eagle
cd eagle
git checkout master
git status


echo "Git remote..."
git remote add upstream https://github.com/apache/incubator-eagle.git
git remote set-url origin "https://${GH_TOKEN}@${GH_REF}"

echo "Set git id..."
git config  user.name "koone"
git config  user.email "luokun@yhd.com"

echo "Fetch..."
git fetch upstream

echo "Rebase..."
git rebase upstream/master

echo "run test"
export PING_SLEEP=30s
export WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export BUILD_OUTPUT=$WORKDIR/build.out
touch $BUILD_OUTPUT

dump_output() {
   echo Tailing the last 500 lines of output:
   tail -500 $BUILD_OUTPUT  
}
error_handler() {
  echo ERROR: An error was encountered with the build.
  dump_output
  exit 1
}
# If an error occurs, run our error handler to output a tail of the build
trap 'error_handler' ERR

# Set up a repeating loop to send some output to Travis.

bash -c "while true; do echo \$(date) - building ...; sleep $PING_SLEEP; done" &
PING_LOOP_PID=$!

# My build is using maven, but you could build anything with this, E.g.
# your_build_command_1 >> $BUILD_OUTPUT 2>&1
# your_build_command_2 >> $BUILD_OUTPUT 2>&1
mvn clean package --quiet >> $BUILD_OUTPUT 2>&1

# The build finished without returning an error so dump a tail of the output
dump_output

# nicely terminate the ping output loop
kill $PING_LOOP_PID


echo "Pushing with force ..."
git push --force origin master > /dev/null 2>&1 || exit 1
echo "Pushed deployment successfully"

set +e
exit 0
