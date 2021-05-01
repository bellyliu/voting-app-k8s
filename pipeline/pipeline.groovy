// Re-usable Function
def buildAndPushDocker(String service){
  def path = "./src/${service}"
  def image = "dekribellyliu/${service}:${env.BUILD_NUMBER}"
  sh "docker build ${path} -t ${image}"
  sh "docker push ${image}"
}

def deployment(String service){
  def manifest_file
  def image_name = "dekribellyliu/${service}:${env.BUILD_NUMBER}"

  if (service != "vote-worker"){
    manifest_file = "./pipeline/deployment-web.yaml"
  } else {
    manifest_file = "./pipeline/deployment-worker.yaml"
  }

  sh "sed -i -e 's/APP_NAME/${service}/g' ${manifest_file}"
  sh "sed -i -e 's/DOCKER_IMAGE/${image_name}/g' ${manifest_file}"
  sh "kubectl apply -f ${manifest_file} -n vote-app"
}

// Pipeline Started Here
def slave = 'demo-pipeline'
podTemplate(
  label: slave,
  containers:[
    containerTemplate(name: 'docker', image: 'docker', ttyEnabled: true, command: 'cat'),
    containerTemplate(name: 'kubectl', image: 'alpine/k8s:1.18.2', ttyEnabled: true, command: 'cat')],
  volumes: [hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock')]
) 
{
  node(slave) {

    stage('Pull Source Code'){
      git changelog: false, credentialsId: 'gihub', poll: false, url: 'https://github.com/bellyliu/voting-app-k8s'
    }  

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

    stage("Deployment"){
      container('kubectl'){
        deployment("results-app")
        deployment("vote-worker")
        deployment("web-vote-app")
      }
    }

  }
}