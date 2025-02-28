# DevOps Project

This repository contains a containerized application that can be built and run using Docker.

## Prerequisites

- Docker installed on your machine
- Git to clone the repository

## Building the Application

1. Clone the repository:

```bash
git clone https://github.com/ValentinLabrune/devops-m2-project
cd devops-m2-project
```

2. Build the Docker image:

```bash
docker build -t devops-m2-project .
```

## Running the Application

Run the container with the following command:

```bash
docker run -p 8081:8080 devops-m2-project
```

The application will be available at `http://localhost:8081`

## Configuration

The application runs on port 8081 by default. To use a different port, modify the port mapping in the docker run
command:

```bash
docker run -p <your-port>:8080 devops-m2-project
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