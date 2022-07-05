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

# Format is:
#   <group>/<version>/<plural>

# shellcheck disable=SC2034
declare -a CRDS=(

com.ericsson.sec.tls/v1alpha1/servercertificates
com.ericsson.sec.tls/v1alpha1/clientcertificates
com.ericsson.sec.tls/v1alpha1/certificateauthorities
siptls.sec.ericsson.com/v1alpha1/internalcertificates
siptls.sec.ericsson.com/v1alpha1/internalusercas
siptls.sec.ericsson.com/v1/internalcertificates
siptls.sec.ericsson.com/v1/internalusercas

)
