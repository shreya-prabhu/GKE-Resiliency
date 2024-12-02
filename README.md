# GKE-Resiliency


## Overview 
This repository provides scripts to performing resiliency testing on **regional** Google Kubernetes Engine (GKE) clusters. These script helps you assess the fault tolerance, recovery mechanisms, and overall robustness of your GKE clusters under various stress scenarios.

GKE Standard Clusters: This approach simulates a zone failure by updating the node pool to restrict it from running in one of the zones. It verifies that your application can respond to the loss of a zone by correctly redistributing Pods and traffic across the remaining zones.

GKE Autopilot Clusters: The approach taken for autopilot clusters is to continuously drain the nodes in the first zone for a set time period. The nodes in the other available zones continue to run. This approach verifies that your application can respond to the loss of all the nodes in a zone by correctly redistributing Pods and traffic across nodes that run in other zones.

> **Note**  
> The script is designed to simulate failover on the nodes hosting a specific application deployment. To do so, you must provide the namespace and deployment name of any service as input through environment variables.


## Prerequisites


#### 1. Environment Setup
Ensure you have the gcloud command-line tool installed. You can install it from [here](https://cloud.google.com/sdk/docs/install)

Authenticate your Google Cloud account and set your project ID

```
gcloud auth login
gcloud config set project PROJECT_ID
```

#### 2. Set environment variables

* GKE Standard:

    If you're testing a GKE Standard cluster, you'll need to configure the following environment variables:

    ```
    export NAMESPACE="default"              # Namespace hosting your deployment
    export DEPLOYMENT_NAME="hello-server"   # Deployment Name
    export GKE_CLUSTER_NAME="cluster-1"     # GKE cluster name
    export REGION="us-central1"             # Region hosting cluster
    export NODE_POOL="default-pool"         # Node Pool name
    export NUM_NODES=2                      # Minimum number of nodes per zone
    ```

* GKE Autopilot:

    If you're testing a GKE Autopilot cluster, set the following environment variables:

    ```
    export NAMESPACE="default"              # Namespace hosting your deployment
    export DEPLOYMENT_NAME="hello-server"   # Deployment Name
    export GKE_CLUSTER_NAME="cluster-1"     # GKE cluster name
    export sleep_interval=120               # Time it takes for your pod to become fully available 
    export max_duration                     # Time duration for which zone should be unavailable
    ```

These environment variables allow the script to interact with your cluster and simulate failure scenarios appropriately.

## Running the script

#### 1. Clone the Repository

```
git clone https://github.com/your-username/GKE-Resiliency.git
cd GKE-Resiliency
cd standard 
```

#### 2. Give Permissions to the script
```
chmod +x standard_resiliency.sh
```

#### 3. Execute the script
```
./standard_resiliency.sh
```