if (branch == "refs/heads/master"){
  build job: 'pipeline-demo', propagate: false, wait: false
}