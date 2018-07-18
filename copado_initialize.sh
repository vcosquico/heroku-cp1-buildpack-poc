#!/bin/bash
COPADO_JOB_ID="$1"

# clone the repo, cleanup, and run the user's job.
. /tmp/copado_clone.sh || exit -3
rm /tmp/copado_clone.sh /tmp/.git_ssh* /tmp/.git_key* &> /dev/null # cleanup now useless information

if [ ! -d /tmp/jobRepository ]; then
    echo "### COPADO: no directory named /tmp/jobRepository. The cloning process might have failed?"
    exit -4
fi

cd /tmp/jobRepository

if [ ! -f copado_start.sh ]; then
    echo "### COPADO: no file named copado_start.sh in the root directory of the repository. The cloning process might have failed?"
    exit -4
fi
echo "### COPADO: ${COPADO_JOB_ID} Starting job"
. copado_start.sh
jobstatus=$?
exit $jobstatus
