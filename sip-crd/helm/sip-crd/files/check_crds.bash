#!/usr/bin/env bash
# Copyright (c) Ericsson AB 2020-2021. All rights reserved.
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
source "$(dirname $0)/logger.bash"
# shellcheck disable=SC1090
source "$(dirname $0)/crds.bash"

[[ -n ${CRDS} ]] || { log_error "CRDS not set" ; exit 1 ; }

log_info "Will wait for the following CRDs: ${CRDS[*]}"

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
curl_out="$(mktemp)"

for crd in "${CRDS[@]}"; do

    log_info "Processing CRD ${crd}"

    [[ ${crd} =~ ${regex} ]] || {
        log_error "CRD is malformed: ${crd}"
        exit 2
    }

    group="${BASH_REMATCH[1]}"
    version="${BASH_REMATCH[2]}"
    plural="${BASH_REMATCH[3]}"

    log_debug "group: ${group}, version: ${version}, plural: ${plural}"

    # Ignore any response but output potential errors
    while ! curl --show-error \
                 --silent \
                 --fail \
                 --cacert "${cacert}" \
                 --output /dev/null \
                 --header "Authorization: Bearer ${token}" \
                 "https://${kube_host}/apis/${group}/${version}/namespaces/${namespace}/${plural}" \
                 > "${curl_out}" 2>&1 ; do

        log_error "Still waiting for CRD ${crd}. Got error: [$(cat "${curl_out}")]"
        sleep 0.1
    done

    log_info "Found CRD ${crd} from API Server"
done

log_info "Found all CRDs successfully"
exit 0
