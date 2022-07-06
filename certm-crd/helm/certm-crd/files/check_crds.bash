#!/usr/bin/env bash
# Copyright (c) Ericsson AB 2020  All rights reserved.
#
# The information in this document is the property of Ericsson.
#
# Except as specifically authorized in writing by Ericsson, the
# receiver of this document shall keep the information contained
# herein confidential and shall protect the same in whole or in
# part from disclosure and dissemination to third parties.
#
# Disclosure and disseminations to the receivers employees shall
# only be made on a strict need to know basis.
#

set -e

# shellcheck disable=SC1090
source "$(dirname $0)/crds.bash"

[[ -n ${CRDS} ]] || exit 1

kube_svc_acc_path=${PATH_FOR_TESTING:-"/var/run/secrets/kubernetes.io/serviceaccount"}

# https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#accessing-the-api-from-a-pod

kube_host='kubernetes.default.svc'
if [[ -r ${kube_svc_acc_path}/host ]] ; then
    # For testing.
    kube_host="$( cat "${kube_svc_acc_path}/host" )"
fi
namespace="$( cat "${kube_svc_acc_path}/namespace" )"
token="$( cat "${kube_svc_acc_path}/token" )"
cacert="${kube_svc_acc_path}/ca.crt"
regex='([^/]+)/([^/]+)/([^/]+)'

for crd in "${CRDS[@]}"; do

    [[ ${crd} =~ ${regex} ]] || {
        exit 2
    }

    group="${BASH_REMATCH[1]}"
    version="${BASH_REMATCH[2]}"
    plural="${BASH_REMATCH[3]}"

    # Wait for CRD and output potential errors.
    # Http error response also results in error exit code 22 due to "--fail" flag for curl.
    while ! curl --fail \
                 --show-error \
                 --silent \
                 --cacert "${cacert}" \
                 --output /dev/null \
                 --header "Authorization: Bearer ${token}" \
                 "https://${kube_host}/apis/${group}/${version}/namespaces/${namespace}/${plural}" \
                 > /dev/null 2>&1 ; do

        sleep 0.1
    done
done

# Add an additional sleep to work around the issue https://github.com/antrea-io/antrea/issues/831
sleep 1

exit 0
