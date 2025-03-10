# DevOps Project

This repository contains a containerized application that can be built, tested, and deployed using a Jenkins pipeline. The pipeline automates the following tasks: checking out the source code, building and pushing a Docker image to Docker Hub, deploying to a development environment using Minikube, testing the application, and finally deploying to production.

Diagram of the pipeline:
![diagram](./diagram.png)

## Prerequisites

- Docker installed on your machine
- Git to clone the repository
- A Kubernetes cluster (e.g., Minikube) to deploy the application
- Jenkins installed and running
- Helm installed on your machine

## Jenkins Pipeline Overview

The Jenkins pipeline is defined in the `Jenkinsfile` and consists of these key stages:

1. **Checkout Code**

   - **What it does:** Clones the repository from GitHub using the specified branch and Git credentials (`gitAccess`).
   - **Why it matters:** Ensures that the latest code is pulled from the repository to be built and deployed.

2. **Build and Push to Docker Hub**

   - **What it does:**
     - Uses the Docker plugin (make sure it is installed in Jenkins) to build the Docker image using the `Dockerfile`.
     - Tags the image with `latest` and pushes it to Docker Hub under the repository specified by `DOCKERHUB_REPO`.
   - **Why it matters:** Automates the container image creation and distribution, making the latest version of your application available in your Docker Hub repository.

3. **Deploy to Minikube - Development**

   - **What it does:**
     - Switches the Kubernetes context to Minikube.
     - Creates (if not already present) a Kubernetes namespace called `development`.
     - Applies the development deployment configuration (`k8s/dev.yaml`) to deploy the application.
   - **Why it matters:** Provides a safe environment to test changes before promoting them to production.

4. **Test Application**

   - **What it does:**
     - Waits for the deployment to initialize.
     - Forwards port `9090` from the deployed service to localhost.
     - Sends an HTTP request to the `/whoami` endpoint to verify that the application is running as expected.
     - Fails the pipeline if the endpoint does not return an HTTP 200 status.
   - **Why it matters:** Automated testing ensures that only successful builds get promoted further.

5. **Deploy to Minikube - Production**
   - **What it does:** Applies the production Kubernetes configuration (`k8s/production.yaml`) in the default namespace.
   - **Why it matters:** Once the build is validated in development, it is deployed to production ensuring a smooth promotion process.

## Setup and Configuration

### Jenkins Configuration

- **Install Jenkins and Plugins:**  
  Ensure that Jenkins is installed and running. Install the necessary plugins:

  - **Docker Plugin:** To build and push Docker images.
  - **Kubernetes CLI Plugin:** For executing `kubectl` commands within the pipeline.

- **Credentials Setup:**

  - **Git Credentials:** Add your GitHub credentials in Jenkins (e.g., with the ID `gitAccess`) to enable repository checkout.
  - **Docker Hub Credentials:** Configure Docker Hub credentials in Jenkins (e.g., with the ID `my-dockerhub-secret`).

- **Kubernetes Secrets:**  
  Create the necessary Kubernetes secrets (if not already set up) to allow the cluster to pull images from Docker Hub. For example:
  ```bash
  kubectl create secret docker-registry my-dockerhub-secret \
    --docker-username=your-dockerhub-username \
    --docker-password=your-dockerhub-password \
    --docker-email=your-email@example.com \
    --namespace=default
  ```
  
## Monitoring

### Deploying Prometheus and Grafana

1. add the following helm repositories:

```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo add grafana https://grafana.github.io/helm-charts
   helm repo update
```

2. Install Prometheus and Grafana:

```bash
   helm install prometheus prometheus-community/prometheus
   helm install grafana grafana/grafana
```

3. Get the Prometheus server URL by running these commands in the same shell:

```bash
   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace default port-forward $POD_NAME 9090
```

4. Get the Grafana URL by running these commands in the same shell:
   ```bash
   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
    kubectl --namespace default port-forward $POD_NAME 3000
   ```
5. Access Prometheus at `http://localhost:9090` and Grafana at `http://localhost:3000`
6. get the Grafana password by running the following command:

```bash
    kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

8. Login to Grafana with the default credentials (username: admin, password: the password you got in the previous step)

### Configuring Grafana

1. Add Prometheus as a data source in Grafana:

   - Open Grafana in your browser at `http://localhost:3000`
   - Log in with the default credentials (username: admin, password: the password you got in the previous step)
   - Click on connections in the left sidebar
   - Click on `Data source` -> `Add data source`
   - Select `Prometheus`
   - Set the URL to `http://prometheus-server.default.svc.cluster.local`
   - Click `Save & Test`

2. Import the dashboard:

   - Click on the `+` icon in the left sidebar
   - Click on `Import`
   - Enter the dashboard ID `1860` in the `Grafana.com Dashboard` field
   - Select the Prometheus data source
   - Click `Load`
   - Click `Import`

3. The dashboard will now be available in the dashboard list in Grafana

4. You can now monitor the application using the Grafana dashboard

### Configuring Alertmanager and Prometheus Alerting Rules

1. Add the target to the Prometheus by applying the following command:

```bash
helm upgrade --reuse-values -f prometheus-targets.yaml prometheus prometheus-community/prometheus
```

2. Edit the `prometheus-alerts-rules.yaml` file to configure the alerting rules.

3. Apply the alerting rules to Prometheus:

```bash
helm upgrade --reuse-values -f prometheus-alerts-rules.yaml prometheus prometheus-community/prometheus
```

3. Access the Prometheus web interface at `http://localhost:9090` and click on `Alerts` to view the alerts

4. You can configure Alertmanager to send alerts to different channels like Slack, PagerDuty, etc.
5. Edit the `alertmanager-config.yaml` file to configure the alerting channels
6. Apply the alerting channels to Alertmanager:

```bash
helm upgrade --reuse-values -f alertmanager-config.yaml prometheus prometheus-community/prometheus
```

7. Access the Alertmanager web interface at `http://localhost:9090` and click on `Alerts` to view the alerts

### Configuring Loki for log management

1. Install Loki:

```bash
helm install loki bitnami/grafana-loki
```

2. Test the connexion on the front:
   - Open Grafana in your browser at `http://localhost:3000`
   - Log in with the default credentials (username: admin, password: the password you got in the previous step)
   - Click on connections in the left sidebar
   - Click on `Data source` -> `Add data source`
   - Choose Loki
   - In the HTTP section, set the URL to :
     - http://loki-grafana-loki-gateway:80
   - Click Save & Test to verify the connection.
   

3. Add the Loki datasource to the Grafana dashboard:
    - Click on the `+` icon in the left sidebar
    - Click on `New Dashboard`
    - Click on `Add Query`
    - Select the Loki data source
    - add the query ``{namespace="production"} |= `error``
    - Click `Save & Test`
