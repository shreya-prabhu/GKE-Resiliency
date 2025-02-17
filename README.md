# GKE-Resiliency

## Overview

This repository provides scripts to performing resiliency testing on **regional** Google Kubernetes Engine (GKE) clusters. These script helps you assess the fault tolerance, recovery mechanisms, and overall robustness of your GKE clusters under various stress scenarios.

#### GKE Standard Clusters:

This approach simulates a zone failure by updating the node pool to restrict it from running in one of the zones. It verifies that your application can respond to the loss of a zone by correctly redistributing Pods and traffic across the remaining zones.

#### GKE Autopilot Clusters:

The approach taken for autopilot clusters is to continuously drain the nodes in the first zone for a set time period. The nodes in the other available zones continue to run. This approach verifies that your application can respond to the loss of all the nodes in a zone by correctly redistributing Pods and traffic across nodes that run in other zones.

> **Note**  
> The script is designed to simulate failover on the nodes hosting a specific application deployment. To do so, you must provide the namespace and deployment name of any service as input through environment variables.

## Prerequisites

#### 1. Environment Setup

Ensure you have the gcloud command-line tool installed. You can install it from [here](https://cloud.google.com/sdk/docs/install)

Authenticate your Google Cloud account and set your project ID

```
gcloud auth login
gcloud config set project <PROJECT_ID>
```

#### 2. Connect to the GKE cluster

Connect to the GKE cluster from the command line, use the following command:

```bash
gcloud container clusters get-credentials <CLUSTER_NAME> --region <REGION> --project <PROJECT_ID>
```

#### 3. Set environment variables

- GKE Standard:

  If you're testing a GKE Standard cluster, you'll need to configure the following environment variables:

  ```
  export NAMESPACE="default"              # Namespace hosting your deployment
  export DEPLOYMENT_NAME="hello-server"   # Deployment Name
  export GKE_CLUSTER_NAME="cluster-1"     # GKE cluster name
  export REGION="us-central1"             # Region hosting cluster
  export NODE_POOL="default-pool"         # Node Pool name
  export NUM_NODES=2                      # Minimum number of nodes per zone
  ```

- GKE Autopilot:

  If you're testing a GKE Autopilot cluster, set the following environment variables:

  ```
  export NAMESPACE="default"              # Namespace hosting your deployment
  export DEPLOYMENT_NAME="hello-server"   # Deployment Name
  export GKE_CLUSTER_NAME="cluster-1"     # GKE cluster name
  export sleep_interval=120               # Time it takes for your pod to become fully available in seconds
  export max_duration=600                 # Time duration for which zone should be unavailable in seconds
  ```

These environment variables allow the script to interact with your cluster and simulate failure scenarios appropriately.

#### 4. IAM permissions for the user/service account
These IAM permissions have to be granted to the user/service account running the script to read and manage cluster resources:
- container.pods.list
- container.nodes.get
- container.nodes.list

Potential roles that can be used are:
- roles/container.admin
- roles/container.clusterAdmin
- roles/container.developer


## Running the script for GKE Standard Clusters

1.  Clone the Repository

```
git clone https://github.com/your-username/GKE-Resiliency.git
cd GKE-Resiliency
cd standard
```

2.  Execute the script

```
./standard_resiliency.sh
```

> **Note**  
> The steps outlined for GKE Standard Clusters also apply to GKE Autopilot Clusters - with the only difference being the `autopilot` folder in Step #1 and `autopilot_resiliency.sh` in Step #2. The commands and configurations remain the same, ensuring a consistent experience across both cluster types.

## References

- [Simulate a zone failure in GKE regional clusters](https://cloud.google.com/kubernetes-engine/docs/tutorials/simulate-zone-failure)
- [Safely Drain a Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
