# Readme
## Description
For this demo, we will use 2 jenkins job. First is `webhook` job that act as webhook receiver from Github, and `pipeline-demo` job that act as pipeline to auto build & deployment the source code to the kubernetes cluster.
![alt text](https://github.com/bellyliu/voting-app-k8s/blob/master/pipeline/pictures/jenkins-job.png?raw=true)

## How the pipeline works and How to deploy changes in repository
The pipeline consist four main stages : 
1. Triggered webhook
2. Pull source code
3. Build and Push Docker Image
4. Deployment to K8s cluster
- See the picture below :
![alt text](https://github.com/bellyliu/voting-app-k8s/blob/master/pipeline/pictures/pipeline.png?raw=true)

#### Triggered webhook
- There is one jenkins Job that trigger another Job when there is `push event` on repository. In this pipeline that job name is `webhook`. Job `webhook` will trigger job `pipeline-demo` when there is `push event` on `master` branch
- The [webhook.groovy](https://github.com/bellyliu/voting-app-k8s/blob/master/pipeline/webhook.groovy) is a simple groovy script that lookup on variable `branch` that send by github. If the `branch` equal to `refs/heads/master` then will start the Job with name `pipeline-demo`
#### Pull source code
- After job `pipeline-demo` was triggered by job `webhook`, the first thing to do is pull source code from this repository
#### Build and Push Docker Image
- When complete pull the source code, it will build docker images from Dockerfile at folder `src`. After that push that image to dockerhub
#### Deployment to K8s Cluster
- Before deployment to k8s cluster, pipeline will adjust the `k8s manifest` (deployment-web.yaml & deployment-worker.yaml) file for each service (results-app, vote-worker, and web-vote-app) using `sed` to adjust the variables inside it.
- Pipeline will use `kubectl apply -f <manifest_file>` to create or update deployment on K8s cluster

## How To Setup Pipeline
#### Setup Kubernetes-plugin
1. This pipeline need Kubernetes-plugin on Jenkins. Fortunatelly it can be auto install when we provision Jenkins using `Helm` with [jenkins-values.yaml](https://github.com/bellyliu/voting-app-k8s/blob/master/helm-charts/jenkins-values.yaml). With Kubernetes-plugin we can spawn a `jenkins-slave` to running a pipeline.
2. Using Kubernetes-plugin, Jenkins will use `default` service account to create/update/delete deployment on kubernetes cluster. But that service account by default can't use for create/update/delete deployment on kubernetes cluster, because of that we should `bind` the `clusterrole` with name admin with service account `default` that used by jenkins. We can do that with this command `kubectl apply -f` [manifest](https://github.com/bellyliu/voting-app-k8s/blob/master/helm-charts/jenkins-clusterrolebinding.yaml)
- Kubernetes-plugin can be installed using jenkins console. `Manage Jenkins` > `Manage Plugin` 
- If using `Helm` the plugin is auto configured. `Manage Jenkins` > `Manage Node and Cloud` > `Configure Clouds`

#### Setup Webhook
1. To create webhook we need install Generic Webhook Trigger Plugin. `Manage Jenkins` > `Manage Plugin` > `Available` > type `Generic Webhook Trigger Plugin` > `Install`
2. Create Job that will accept `webhook` from github. For example we create with name `webhook`.
3. Configure the `Build Triggers` with check the `Generic Webhook Trigger` option.
4. Then configured like this and click Save :
![alt text](https://github.com/bellyliu/voting-app-k8s/blob/master/pipeline/pictures/config-generic-webhook.png?raw=true)
5. After that configure the pipeline section to use [webhook.groovy](https://github.com/bellyliu/voting-app-k8s/blob/master/pipeline/webhook.groovy) for this job. See the picture below :
![alt text](https://github.com/bellyliu/voting-app-k8s/blob/master/pipeline/pictures/webhook-pipeline-config.png?raw=true)
6. Click save
7. After that we should create webhook on repository. For repository github `Settings` > `Webhook`
8. Then configured like this and click Update webhook :
![alt text](https://github.com/bellyliu/voting-app-k8s/blob/master/pipeline/pictures/github-webhook.png?raw=true)
- `$.ref` is one of json payload from github that send to jenkins.
![alt text](https://github.com/bellyliu/voting-app-k8s/blob/master/pipeline/pictures/github-webhook-payload.png?raw=true)
9. `Payload URL` consist of (http or https)://(username):(api_token)@(jenkins_url or jenkins_ip)/generic-webhook-trigger/invoke
- Please refer to this : [create-api-token](https://stackoverflow.com/questions/45466090/how-to-get-the-api-token-for-jenkins) and [generic-webhook-trigger](https://plugins.jenkins.io/generic-webhook-trigger/) 
10. Setup webhook done

#### Setup Pipelines
1. Create pipeline job with name `pipeline-demo`. `New item` > Choose `pipeline` and type `pipeline-demo` > `save`
2. Configured the pipeline like this and save :
![alt text](https://github.com/bellyliu/voting-app-k8s/blob/master/pipeline/pictures/config-pipeline-demo.png?raw=true)
3. Setup pipeline done

#### How do i create pipeline.groovy
1. Prepare the pod templates. With Kubernetes-plugin we can create a pod template as jenkins-slave for running a pipeline. So, when pipeline started it will spawn a pod as jenkins-slave and all processes will happend on jenkins-slave instead of jenkins master. Please refer to [Kubernetes-plugin](https://plugins.jenkins.io/kubernetes/) for more detail
``` def slave = 'demo-pipeline'
    podTemplate(
      label: slave,
      containers:[
        containerTemplate(name: 'docker', image: 'docker', ttyEnabled: true, command: 'cat'),
        containerTemplate(name: 'kubectl', image: 'alpine/k8s:1.18.2', ttyEnabled: true, command: 'cat')],
      volumes: [hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock')]
    ) 
```
2. Create stage to pull all source code from repo.
```
    stage('Pull Source Code'){
      git changelog: false, credentialsId: 'gihub', poll: false, url: 'https://github.com/bellyliu/voting-app-k8s'
    }  
```
3. Create stage to build and push docker image to dockerhub. We need to create `credential` that containt username and password to push docker image to dockerhub. In this stage we use container `docker` to build and push the image, because of that we can execute command `docker build, docker login` etc.
```
    stage('Build & Push Docker Image') {
      withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'password', usernameVariable: 'username')]) {
        container('docker') {
          sh "docker login -u ${username} -p ${password}"
          buildAndPushDocker("results-app")
          buildAndPushDocker("vote-worker")
          buildAndPushDocker("web-vote-app")
        }
      }
    }
```
- `buildAndPushDocker()` is function to build the docker image from Dockerfile inside `src` folder, then push the docker image.
```
    def buildAndPushDocker(String service){
      def path = "./src/${service}"
      def image = "dekribellyliu/${service}:${env.BUILD_NUMBER}"
      sh "docker build ${path} -t ${image}"
      sh "docker push ${image}"
    }
```
4. Create stage to deploy the newest image to kubernetes
```
    stage("Deployment"){
      container('kubectl'){
        deployment("results-app")
        deployment("vote-worker")
        deployment("web-vote-app")
      }
    }
```
- `deployment()` is function to adjust the variables inside `<manifest-file>`. After that execute `kubectl apply -f <manifest-file> -n vote-app` for deploy to kubernetes cluster
```
def deployment(String service){
  def template

  if (service != "vote-worker"){
    template = "./pipeline/deployment-web.yaml"
  } else {
    template = "./pipeline/deployment-worker.yaml"
  }
  sh "cp ${template} deployment.yaml"
  sh "sed -i -e 's/APP_NAME/${service}/g' deployment.yaml"
  sh "sed -i -e 's/REGISTRY/dekribellyliu/g' deployment.yaml"
  sh "sed -i -e 's/SERVICE_NAME/${service}/g' deployment.yaml"
  sh "sed -i -e 's/IMAGE_VERSION/${env.BUILD_NUMBER}/g' deployment.yaml"
  sh "kubectl apply -f deployment.yaml -n vote-app"
  sh "rm -rf deployment.yaml"
}
``` 
5. Done