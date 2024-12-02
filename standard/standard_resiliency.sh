#!/bin/bash

# Set your variables here
# NAMESPACE="default"              # Namespace hosting your deployment
# DEPLOYMENT_NAME="hello-server"   # Deployment Name
# GKE_CLUSTER_NAME="cluster-1"     # GKE cluster name
# REGION="us-central1"             # Region hosting cluster
# NODE_POOL="default-pool"         # Node Pool name
# NUM_NODES=2                      # Minimum number of nodes per zone

echo "Starting GKE Standard Cluster Disaster Recovery Simulation"

# Capture start time
start_time=$(date)
echo -e "\nSimulation started at: $start_time"

sleep 5

echo -e "\nIn this simulation, we will simulate a zonal outage by updating the node pool to restrict nodes to certain zones."
echo "This will cause the application pods to be drained from nodes in the specified target zone."
echo "The final placement of the application pods will depend on GKE's scheduling decisions within the available zones."

echo -e "\nPre-Failover, the time is : "
date

echo -e "----Application Pod details ----"
kubectl get pods -n "$NAMESPACE" -o wide --field-selector metadata.namespace!=kube-system | grep "$DEPLOYMENT_NAME"

sleep 5

echo -e "\n----Node Details of the cluster----"
kubectl get nodes -o=custom-columns='NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone'

sleep 5

# Step 1: Identify the failure zone (the zone of the first pod in the deployment)
NODE_NAME=$(kubectl get pods -n "$NAMESPACE" -o wide --field-selector metadata.namespace!=kube-system | grep "$DEPLOYMENT_NAME" | awk '{print $7}' | head -n 1)  # Get node where first pod resides

if [ -z "$NODE_NAME" ]; then
  echo "Error: No node found hosting the deployment. Exiting."
  exit 1
fi

FAILURE_ZONE=$(kubectl get nodes -o=custom-columns='NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone' | grep "$NODE_NAME" | awk '{print $2}') #get zone where that node resides

echo -e "\n---- Target failure zone chosen is $FAILURE_ZONE ----"

sleep 5

echo -e "\n---- Nodes in the cluster before update ----"
kubectl get node -o=custom-columns='NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone,INT_IP:.status.addresses[0].address'

sleep 5

# Capture date and time before updating node pool
pre_update_time=$(date)
echo -e "\n Time before simulating the zone failover: $pre_update_time"

# Step 3: Update the node pool to run only in the specified zones (excluding the failure zone)
# You can specify the zones where you want the node pool to remain operational (other than the failure zone)
ZONE_SUFFIXES=("a" "b" "c")   # Known zone suffixes (expand as needed)
ALL_ZONES=$(printf "%s," "${ZONE_SUFFIXES[@]/#/$REGION-}")
ALL_ZONES=${ALL_ZONES%,}

AVAILABLE_ZONES=$(gcloud compute zones list --filter="name ~ '$REGION.*' AND name != '$FAILURE_ZONE'" --format="value(name)" | tr '\n' ',') AVAILABLE_ZONES=${AVAILABLE_ZONES%,} # Remove the trailing comma
echo -e "\nExcluding the failure zone $FAILURE_ZONE, the available zones are: $AVAILABLE_ZONES"

sleep 5

echo -e "\nUpdating node pool to restrict nodes to zones $AVAILABLE_ZONES, excluding the target failure zone ($FAILURE_ZONE)..."
echo " gcloud container node-pools update $NODE_POOL --cluster=$GKE_CLUSTER_NAME --node-locations=$AVAILABLE_ZONES --region=$REGION"
gcloud container node-pools update $NODE_POOL --cluster=$GKE_CLUSTER_NAME --node-locations=$AVAILABLE_ZONES --region=$REGION

# Capture date and time after updating node pool
post_update_time=$(date)
echo -e "\nNode pool update completed at: $post_update_time"

# Step 4: Verify the update
echo -e "\nVerifying the updated pod status and node locations after node pool update..."

echo -e "\n---- Pods in the cluster after update ----"
kubectl get pods -n "$NAMESPACE" -o wide --field-selector metadata.namespace!=kube-system | grep "$DEPLOYMENT_NAME"

echo -e "\n---- Nodes in the cluster after update ----"
kubectl get node -o=custom-columns='NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone,INT_IP:.status.addresses[0].address'

echo -e "\nDisaster recovery simulation completed. The node pool was restricted to the specified zones, and application pods were rescheduled according to GKE's scheduling policies."

date
sleep 5

echo -e "Restoring normal state of node pool by including all zones of the region"

echo "Updating node pool to schedule across all available zones $ALL_ZONES"

# gcloud command to update node pools
gcloud container node-pools update $NODE_POOL --cluster=$GKE_CLUSTER_NAME --node-locations=$ALL_ZONES --region=$REGION

gcloud container clusters resize $GKE_CLUSTER_NAME --node-pool $NODE_POOL --num-nodes $NUM_NODES

echo "Time after normalization of cluster"
date

echo "all nodes"

kubectl get nodes