#!/bin/bash
set -e
get_files="$(find ./kafka-stateless -name "*.yaml"|awk -F '/' '{print $NF}')"
path_dir="./kafka-stateless"
get_ingress_beta="$(kubectl describe svc kafka-service -n beta|grep -i ingress|awk '{print $NF}')"
get_ingress_alpha="$(kubectl describe svc kafka-service -n alpha|grep -i ingress|awk '{print $NF}')"
filename=$0

function beta(){
  for index in ${get_files};do
    sed "s/<REALM>/beta/g" ${path_dir}/${index} > ${path_dir}/${index}.tmp
    if [[ ${index} == 'kafka-broker.yaml' ]];then
      echo -e "applying KAFKA_ADVERTISED_HOST_NAME to kafka-broker"
      sed -i "s/<REALM>/beta/g;s/<KAFKA_ADVERTISED_HOST_NAME>/'$(echo "${get_ingress_beta}")\'/g" ${path_dir}/kafka-broker.yaml.tmp
    fi
    echo -e "deploying ${index}"
    kubectl apply -f ${path_dir}/${index}.tmp
  done
}

function alpha(){
  for index in ${get_files};do
    sed "s/<REALM>/alpha/g" ${path_dir}/${index} > ${path_dir}/${index}.tmp
    echo -e "kubectl apply to ${path_dir}/${index}"
    if [ ${index} == 'kafka-broker.yaml' ];then
      echo -e "applying KAFKA_ADVERTISED_HOST_NAME to kafka-broker"
      sed -i "s/<REALM>/alpha/g;s/value:\ <KAFKA_ADVERTISED_HOST_NAME>/value:\ '$(echo "${get_ingress_alpha}")\'/g" ${path_dir}/kafka-broker.yaml.tmp
    fi
    echo -e "deploying ${index}"
  done
}

function cleanup(){
  for index in ${get_files};do rm -f ${path_dir}/${index}.tmp;done
}

if [ $# -lt 1 ];then
  echo -e "exiting due to zero argument"
  echo -e "\n./$(basename ${filename}) [alpha|beta]"
  exit 1
elif [ ! -d kafka-stateless ];then
  echo -e "directory kafka-stateless is not found\nexitting with code 1"
  exit 1
fi

case $1 in
 'alpha')echo -e "deploy kafka to alpha";cleanup;alpha;kubectl apply -f ${path_dir}/${index}.tmp;;
 'beta')echo -e "deploy kafka to beta";cleanup;beta;;
 'cleanup')echo -e "cleaning up";cleanup;;
 *)echo -e "\n\n$1 is not an option\n$(basename ${filename}) [alpha|beta]"
esac
