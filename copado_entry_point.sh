#!/bin/bash
COPADO_JOB_ID="$1"
jobstatus=-1
isFinished=
set -e; set -o pipefail # tell bash to fail early (otherwise the shell script continues)

# upon exit, change the status, then upload logs + exitCode via our API
function finish {
    if [ -n "$isFinished" ]; then exit $jobstatus; fi
    isFinished=1
    jobstatus="${1:-$jobstatus}"
    echo "### COPADO: ${COPADO_JOB_ID} Job finished. exit code=${jobstatus}" | tee -a /tmp/copado_logs.txt
    curl -sSX POST https://${COPADO_ENDPOINT_HOSTNAME}/c1p/job/st1atus/${COPADO_JOB_ID} -H "X-Client-Key: ${COPADO_CLIENT_KEY}" -o /tmp/copado.response1.txt --write-out "COPADO.REQ: %{http_code} %{time_total} %{url_effective} " --connect-timeout 10; cat /tmp/copado.response1.txt; echo
    sync && sleep 1s
    curl -sSX POST https://${COPADO_ENDPOINT_HOSTNAME}/c1p/job/finish/${COPADO_JOB_ID}/${jobstatus} -H "X-Client-Key: ${COPADO_CLIENT_KEY}" -o /tmp/copado.response2.txt --write-out "COPADO.REQ: %{http_code} %{time_total} %{url_effective} " --form file=@"/tmp/copado_logs.txt" --connect-timeout 10; cat /tmp/copado.response2.txt; echo
}
trap finish EXIT
trap "finish -1" SIGINT SIGTERM

# contact our API to indicate the job has started, and to return.
STATUS_CODE=$(curl -sSX POST https://${COPADO_ENDPOINT_HOSTNAME}/c1p/job/script/${COPADO_JOB_ID} -H "X-Client-Key: ${COPADO_CLIENT_KEY}" -o /tmp/copado_clone.sh --write-out "COPADO.REQ: %{http_code} %{time_total} %{url_effective}\n" --connect-timeout 10 || exit -1)
if [[ "$STATUS_CODE" != "COPADO.REQ: 200 "* ]]; then "### retrive start script error ($STATUS_CODE) $(cat /tmp/copado_clone.sh)"; exit -2; else echo "$STATUS_CODE"; fi

. copado_initialize.sh $* 2>&1 | tee -a /tmp/copado_logs.txt
jobstatus=$?
