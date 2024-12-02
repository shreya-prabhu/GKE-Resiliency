#!/bin/bash

# Pre-Requisites : Ensure the following environment variables are set #

# NAMESPACE="default"
# DEPLOYMENT_NAME="hello-server"
# PROJECT_ID="project"
# sleep_interval=120               # Time it takes for your pod to become fully available 
# max_duration                     # Time duration for which zone should be unavailable

echo "Starting GKE Autopilot Disaster Recovery Simulation"

echo -e "\nIn this simulation, we will emulate a zonal outage over the next 10 minutes. During this period, the application pods will be drained from the nodes within a specified target zone." 
echo "Since GKE Autopilot does not provide full user control over the location of node pools, we will attempt to simulate zone unavailability by continuously draining nodes in the designated zone."
echo " The final placement of the application pods will depend on the scheduling decisions made by Autopilot, which may assign the pods to nodes in different zones based on its internal policies."


echo -e "\nPre-Draining, the time is : "
date

echo -e "----Application Pod details ----"
kubectl get pods -n "$NAMESPACE" -o wide --field-selector metadata.namespace!=kube-system | grep "$DEPLOYMENT_NAME"

echo -e "\n----Node Details of the cluster----"
kubectl get nodes -o=custom-columns='NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone'
ALL_NODES=$(kubectl get pods -n "$NAMESPACE" -o wide --field-selector metadata.namespace!=kube-system | awk '{print $7}')
NODE_NAME=$(kubectl get pods -n "$NAMESPACE" -o wide --field-selector metadata.namespace!=kube-system | grep "$DEPLOYMENT_NAME" | awk '{print $7}' | head -n 1)  # Get node of first pod

if [ -z "$NODE_NAME" ]; then
  echo "Error: No node found hosting the deployment. Exiting."
  exit 1
fi

echo -e "\n----Target node chosen is $NODE_NAME ----"
FAILURE_ZONE=$(kubectl get nodes -o=custom-columns='NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone' | grep "$NODE_NAME" | awk '{print $2}')

echo -e "----\n\n We will drain the node and zone hosting the first pod in deployment list ----"

echo -e "\n---- Target node chosen is $NODE_NAME in zone $FAILURE_ZONE ----"
echo "---- Attempting to drain nodes in $FAILURE_ZONE ----"

echo -e "\nDraining of nodes started at :"
date

# Start time tracking
start_time=$(date +%s)

# Maximum duration in seconds (10 minutes = 600 seconds)
max_duration=600  # 10 minutes

# Sleep interval between checks 
sleep_interval=60

# Main loop for draining and observing rescheduling
while true; do
  
  # Get current time and calculate elapsed time
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))

  ALL_NODES=$(kubectl get pods -n "$NAMESPACE" -o wide --field-selector metadata.namespace!=kube-system | grep "$DEPLOYMENT_NAME" | awk '{print $7}')
  ALL_ZONES=$(kubectl get nodes -o=custom-columns='NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone' | grep -F "$ALL_NODES" | awk '{print $2}')

  echo -e "\nCurrent nodes hosting $DEPLOYMENT_NAME: $ALL_NODES"
  echo -e "\nZones hosting $DEPLOYMENT_NAME: $ALL_ZONES"

  # Check if failover occurred by ensuring no pods are in the original failure zone
  if ! echo "$ALL_ZONES" | tr -d '\n' | grep -q "$FAILURE_ZONE"; then
    echo -e "\nNo pods starting with $DEPLOYMENT_NAME are in zone $FAILURE_ZONE. Failover is successful."
    echo -e "The failover was successful, as GKE Autopilot provisioned a new node in a zone distinct from the original failure zone."
    break
  else

  # Check if the elapsed time exceeds the max duration
  if [ $elapsed_time -ge $max_duration ]; then
    echo -e "\nAt the conclusion of this disaster recovery exercise, the pod has been rescheduled in the same target zone."
    echo -e "This behavior is a result of the lack of user control over the location of node pools in Autopilot Clusters."
    echo -e "However, it is important to note that the pod has been rescheduled on a new node, and the original node prior to draining would be terminated."
    break
  fi

  echo -e "\nPods starting with $DEPLOYMENT_NAME are still found in zone $FAILURE_ZONE. Retrying drain operation.\n"
    
  kubectl get nodes -o name -l "topology.kubernetes.io/zone=$FAILURE_ZONE" | xargs -I {} kubectl drain {} --namespace=$NAMESPACE --ignore-daemonsets --delete-emptydir-data --force --disable-eviction=true
    if [ $? -ne 0 ]; then
      echo "Warning: Drain operation failed due to GKE Autopilot restrictions."
    fi

    echo -e "\nSleeping for $sleep_interval seconds before rechecking..."
    sleep $sleep_interval
  fi
done

echo -e "\n---- Post-Drain Pod Status at ----"
date

kubectl get pods -n "$NAMESPACE" -o wide --field-selector metadata.namespace!=kube-system

echo -e "\n---- Post-Drain Nodes Hosting Application Pod ----"
kubectl get nodes -o=custom-columns='NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone'
