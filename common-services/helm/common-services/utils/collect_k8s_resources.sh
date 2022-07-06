#!/bin/bash

############################################################################
# organization "Ericsson AB";                                              #
# description "Script to collect logs for Support.                         #
#        Copyright (c) 2020 Ericsson AB. All rights reserved.";            #
############################################################################
# Author: EPRGGGZ Gustavo Garcia G.                                        #
#                                                                          #
# Script to collect logfiles for Kubernetes Cluster based on Spider input  #
# The script wil also collect HELM charts configuration                    #
# To use, execute collect_k8s_resources.sh <namespace>                          #
#                                                                          #
############################################################################

############################################################################
#                          History                                         #
#                                                                          #
# 2021-01-18 ENIVPAL    Based on collect_ADP_logs.sh                       #
#                       Cleanup and fixed event log collections            #
#                       removed cmy_log,  cmm_log and rename file          #
#                                                                          #
############################################################################

#Fail if empty argument received
if [[ "$#" != "1" ]]; then
  echo "Wrong number of arguments"
  echo "Usage collect_k8s_resources.sh <Kubernetes_namespace>"
  echo "ex:"
  echo "$0 default  #--- to gather the logs for namespace 'default'"
  exit 1
fi

if [[ `kubectl get namespace $1 | wc -l` = "0" ]]; then
  echo "Given namespace $1 not exist."
  exit 1
fi

namespace=$1
#Create a directory for placing the logs
log_base_dir=logs_${namespace}_$(date "+%Y-%m-%d-%H-%M-%S")
log_base_path=$PWD/${log_base_dir}
mkdir ${log_base_dir}
#Check if there is helm2  or helm3 deployment

kubectl version >$log_base_path/k8s_version.txt
helm version | head -1 >$log_base_path/helm_version.txt
if eval ' grep v3 $log_base_path/helm_version.txt'
then
  echo "HELM 3 identified"
  HELM='helm get all --namespace='${namespace}
else
  HELM='helm get'
fi

get_describe_info() {
  #echo "---------------------------------------"
  echo "-Getting logs for describe info-"
  #echo "---------------------------------------"
  #echo "---------------------------------------"

  des_dir=${log_base_path}/describe
  mkdir ${des_dir}
  for attr in statefulsets crd deployments services replicasets endpoints daemonsets persistentvolumeclaims configmap pods nodes jobs persistentvolumes rolebindings roles secrets serviceaccounts storageclasses ingresses
  do
    mkdir ${des_dir}/$attr
    kubectl --namespace ${namespace} get $attr > ${des_dir}/$attr/$attr.txt
    echo "Getting describe information on $attr.."
    for i in `kubectl --namespace ${namespace} get $attr | grep -v NAME | awk '{print $1}'`
    do
      kubectl --namespace ${namespace} describe $attr $i > ${des_dir}/$attr/$i.txt
    done
  done
}
get_events() {
  echo "-Getting list of events-"
  mkdir ${des_dir}/events

  kubectl --namespace ${namespace} get events > ${des_dir}/events/events.txt
}
get_pods_logs() {
  #echo "---------------------------------------"
  echo "-Getting logs per POD-"
  #echo "---------------------------------------"
  #echo "---------------------------------------"

  logs_dir=${log_base_path}/logs
  mkdir ${logs_dir}
  mkdir ${log_base_path}/env
  kubectl --namespace ${namespace} get pods > ${logs_dir}/kube_podstolog.txt
  for i in `kubectl --namespace ${namespace} get pods | grep -v NAME | awk '{print $1}'`
  do
    for j in `kubectl --namespace ${namespace} get pod $i -o jsonpath='{.spec.containers[*].name}'`
    do
      kubectl --namespace ${namespace} logs $i -c $j > ${logs_dir}/${i}_${j}.txt
      kubectl --namespace ${namespace} logs $i -c $j -p > ${logs_dir}/${i}_${j}_prev.txt &2>/dev/null
      kubectl --namespace ${namespace} exec  $i -c $j -- env > ${log_base_path}/env/${i}_${j}_env.txt
    done
  done
}

get_helm_info() {
  #echo "-----------------------------------------"
  echo "-Getting Helm Charts for the deployments-"
  #echo "-----------------------------------------"
  #echo "-----------------------------------------"

  helm_dir=${log_base_path}/helm
  mkdir ${helm_dir}
  helm --namespace ${namespace} list > ${helm_dir}/helm_deployments.txt

  for i in `helm --namespace ${namespace} list| grep -v NAME | awk '{print $1}'`
  do
    #echo $i
    #helm get $i > ${helm_dir}/$i.txt
    #$HELM $i --namespace ${namespace}> ${helm_dir}/$i.txt
    $HELM $i > ${helm_dir}/$i.txt
    echo $HELM $i
  done
}

siptls_logs() {

  #echo "-----------------------------------------"
  echo "-Verifying for SIP-TLS logs -"
  #echo "-----------------------------------------"
  #echo "-----------------------------------------"

  siptls_log_dir=${log_base_path}/logs/siptls_log

  if (kubectl --namespace=${namespace} get pods | grep -i sip-tls)
    then
    mkdir ${siptls_log_dir}
    echo "SIP-TLS Pods found, gathering siptls_logs.."
    for i in `kubectl --namespace=${namespace} get pods | grep -i sip-tls | awk '{print $1}'`
    do
      echo $i
      kubectl --namespace ${namespace} exec $i -- /bin/bash /sip-tls/sip-tls-alive.sh && echo $? > ${siptls_log_dir}/alive_log_$i.out
      kubectl --namespace ${namespace} exec $i -- /bin/bash /sip-tls/sip-tls-ready.sh && echo $? > ${siptls_log_dir}/ready_log_$i.out
      kubectl logs --namespace ${namespace}  $i sip-tls-init > ${siptls_log_dir}/sip-tls-init_logs_pod__$i.out
      kubectl logs --namespace ${namespace}  $i sip-tls-init --previous > ${siptls_log_dir}/sip-tls-init-previous_log_$i.out
      kubectl logs --namespace ${namespace}  $i sip-tls > ${siptls_log_dir}/sip-tls_log__$i.out
      kubectl logs --namespace ${namespace}  $i sip-tls-init --previous > ${siptls_log_dir}/sip-tls-previous_log_$i.out
      kubectl --namespace ${namespace} exec $i -- env > ${siptls_log_dir}/env_log__$i.out
    done
    kubectl --namespace ${namespace} logs eric-sec-key-management-main-0  kms-mon> ${siptls_log_dir}/kms-mon.out
    kubectl --namespace ${namespace} logs eric-sec-key-management-main-0  kms-mon --previous > ${siptls_log_dir}/kms-mon_prev.out
    kubectl --namespace ${namespace} logs eric-sec-key-management-main-0  -c kms-ca> ${siptls_log_dir}/kms-ca.out
    kubectl --namespace ${namespace} logs eric-sec-key-management-main-0  -c kms-ca> ${siptls_log_dir}/kms-ca_prev.out
    kubectl --namespace ${namespace} exec eric-sec-key-management-main-0 -c kms -- bash -c 'vault status -tls-skip-verify' > ${siptls_log_dir}/vault_status_kms.out
    kubectl --namespace ${namespace} exec eric-sec-key-management-main-0 -c shelter -- bash -c 'vault status -tls-skip-verify' > ${siptls_log_dir}/vault_status_shelter.out
    kubectl get crd --namespace ${namespace}  servercertificates.com.ericsson.sec.tls -o yaml  > ${siptls_log_dir}/servercertificates_crd.out
    kubectl get  --namespace ${namespace}  servercertificates -o yaml  > ${siptls_log_dir}/servercertificates.out
    kubectl get crd --namespace ${namespace}  clientcertificates.com.ericsson.sec.tls -o yaml  > ${siptls_log_dir}/clientcertificates_crd.out
    kubectl get  --namespace ${namespace}  clientcertificates -o yaml  > ${siptls_log_dir}/clientcertificates.out
    kubectl get crd --namespace ${namespace} certificateauthorities.com.ericsson.sec.tls -o yaml  > ${siptls_log_dir}/certificateauthorities_crd.out
    kubectl get  --namespace ${namespace}  certificateauthorities -o yaml  > ${siptls_log_dir}/certificateauthorities.out
    kubectl get  --namespace ${namespace}  internalcertificates.siptls.sec.ericsson.com  -o yaml  > ${siptls_log_dir}/internalcertificates.out
    kubectl get  --namespace ${namespace}  internalusercas.siptls.sec.ericsson.com  -o yaml  > ${siptls_log_dir}/internalusercas.out
    kubectl get secret --namespace ${namespace} -l com.ericsson.sec.tls/created-by=eric-sec-sip-tls > ${siptls_log_dir}/secrets_created_by_eric_sip.out
    pod_name=$(kubectl get po -n ${namespace} -l app=eric-sec-key-management -o jsonpath="{.items[0].metadata.name}")
    kubectl --namespace ${namespace} exec $pod_name -c kms -- env VAULT_SKIP_VERIFY=true vault status > ${siptls_log_dir}/kms_status_.out
  else
     echo "SIP-TLS Containers not found or not running, doing nothing"
  fi
}

compress_files() {
  echo "Generating tar file and removing logs directory..."
  tar cvfz $PWD/${log_base_dir}.tgz ${log_base_dir}
  echo  -e "\e[1m\e[31mGenerated file $PWD/${log_base_dir}.tgz, Please collect and send to Support!\e[0m"
  rm -r $PWD/${log_base_dir}
}

get_describe_info
get_events
get_pods_logs
get_helm_info
compress_files
