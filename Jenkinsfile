#!/usr/bin/groovy
// Docker Image Build Script For kubernetes

// Load Pipeline Functions - pipeline-github-lib plugin Is Required For This
@Library('github.com/geoffh1977/k8s-pipeline-lib')
def pipeline = new org.pipeline.Pipeline()

// Specify Kuernetes Pod Template For Operations
podTemplate(label: 'nginx-site-demo-pipeline', containers: [
    containerTemplate(name: 'jnlp', image: 'jenkins/jnlp-slave:latest', args: '${computer.jnlpmac} ${computer.name}', resourceRequestCpu: '200m', resourceLimitCpu: '200m', resourceRequestMemory: '512Mi', resourceLimitMemory: '512Mi'),
    containerTemplate(name: 'docker', image: 'docker:17.03.2-ce', command: 'cat', ttyEnabled: true)
],
volumes:[
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
]){

  // Start Building Pipeline For Jenkins
  node ('nginx-site-demo') {

    // Clone In The Git Repository
    stage ('Clone Repository') {
      checkout scm
    }
    def pwd = pwd()
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
    }

    // Set Account To Push To From Branch Name
    def acct = pipeline.getContainerRepoAcct(config)
    // Tag Docker Image With version, And branch-commit_id
    def image_tags_map = pipeline.getContainerTags(config)
    // Compile Tag List From Tag Map
    def image_tags_list = pipeline.getMapValues(image_tags_map)

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
  }
}