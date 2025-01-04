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

The application runs on port 8081 by default. To use a different port, modify the port mapping in the docker run command:
```bash
docker run -p <your-port>:8080 devops-app
```