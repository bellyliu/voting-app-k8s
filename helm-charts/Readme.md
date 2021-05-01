# Readme
Install `jenkins`, `redis`, and `postgresql` to kubernetes cluster hosted on alibabacloud using `helm`.

# Requirements
- namespace with name `jenkins` and `vote-app`

## Install Jenkins
- `helm install -f jenkins-values.yaml jenkins ./jenkins` 
- `kubectl apply -f jenkins-clusterrlebinding.yaml`

## Install Redis
- `helm install -f redis-values.yaml redis01 ./redis`

## Install Postgresql
- `helm install -f postgres-values.yaml store ./postgresql`