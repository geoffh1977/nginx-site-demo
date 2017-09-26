#!/usr/bin/groovy
// Docker Image Build Script For kubernetes

// Load Pipeline Functions - pipeline-github-lib plugin Is Required For This
@Library('github.com/geoffh1977/k8s-pipeline-lib')
def pipeline = new org.pipeline.Pipeline()

// Specify Kuernetes Pod Template For Operations
podTemplate(label: 'nginx-site-demo-pipeline', containers: [
    containerTemplate(name: 'jnlp', image: 'jenkins/jnlp-slave:latest', args: '${computer.jnlpmac} ${computer.name}', resourceRequestCpu: '200m', resourceLimitCpu: '200m', resourceRequestMemory: '512Mi', resourceLimitMemory: '512Mi'),
    containerTemplate(name: 'docker', image: 'docker:17.03.2-ce', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'helm', image: 'geoffh1977/k8s-helm:2.6.1', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'kubectl', image: 'geoffh1977/k8s-kubectl:latest', command: 'cat', ttyEnabled: true)
],
volumes:[
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
]){

  // Start Building Pipeline For Jenkins
  node ('nginx-site-demo-pipeline') {

    // Clone In The Git Repository
    stage ('Clone Repository') {
      checkout scm
    }
    def pwd = pwd()
    def chart_dir = "${pwd}/charts/nginx-site-demo"
    // Read In The Required Workflow Values
    def inputFile = readFile('Jenkinsfile.json')
    def config = new groovy.json.JsonSlurperClassic().parseText(inputFile)
    println "Pipeline Config => ${config}"

    // Only Continue If The Pipeline Variable Is Enabled
    if (!config.pipeline.enabled) {
      println "Pipeline Disabled - Skipping"
      return
    }

    // Set Additional Git Environment Variables For Tagging
    pipeline.gitEnvVars()

    // Debug Mode Enabled - Display Extra Information
    if (config.pipeline.debug) {
      println "Debug Mode Enabled"
      sh "env | sort"

      println "Running Kubectl And Helm Tests"
      container('kubectl') {
        pipeline.kubectlTest()
      }
      container('helm') {
        pipeline.helmConfig()
      }

    }

    // Set Account To Push To From Branch Name
    def acct = pipeline.getContainerRepoAcct(config)
    // Tag Docker Image With version, And branch-commit_id
    def image_tags_map = pipeline.getContainerTags(config)
    // Compile Tag List From Tag Map
    def image_tags_list = pipeline.getMapValues(image_tags_map)

    // Test Deployment Code Before Building Container
    stage ('Test Deploy Code') {
      container('helm') {
        // Lint Helm Chart Code
        pipeline.helmLint(chart_dir)

        // Dry-Run Deployment
        pipeline.helmDeploy(
          dry_run       : true,
          name          : config.app.name,
          namespace     : config.app.name,
          version_tag   : image_tags_list.get(0),
          chart_dir     : chart_dir,
          replicas      : config.app.replicas,
          cpu           : config.app.cpu,
          memory        : config.app.memory,
          hostname      : config.app.hostname
        )
      }
    }

    // Build And Publish Container Image
    stage ('Buld/Publish Container Image') {
      container('docker') {
        pipeline.containerBuildPub(
            dockerfile: config.container_repo.dockerfile,
            host      : config.container_repo.host,
            acct      : acct,
            repo      : config.container_repo.repo,
            tags      : image_tags_list,
            auth_id   : config.container_repo.jenkins_creds_id
        )
      }
    }

    // Live Deploy Only If Branch Is Master
    if (env.BRANCH_NAME == 'master') {
      stage ('Deploy To K8s') {
        container('helm') {
          // Deploy Using Helm Chart
          pipeline.helmDeploy(
            dry_run       : false,
            name          : config.app.name,
            namespace     : config.app.name,
            version_tag   : image_tags_list.get(0),
            chart_dir     : chart_dir,
            replicas      : config.app.replicas,
            cpu           : config.app.cpu,
            memory        : config.app.memory,
            hostname      : config.app.hostname
          )

          //  Run Helm Tests On Deployment
          if (config.app.test) {
            pipeline.helmTest(
              name          : config.app.name
            )
          }
        }
      }
    }
  }
}
