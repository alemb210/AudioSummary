pipeline {
  agent any

  environment {
    CF_DIST_ID = credentials('cf-dist-id')
  }

  stages {
    stage('Checkout Source') {
      steps {
        git branch: "main",
            url: 'git@github.com:alemb210/AudioSummary.git'
      }
    }

    stage('Install') {
      steps {
        dir('frontend') {
          sh 'npm install'
        }
      }
    }

    stage('Build') {
      steps {
        dir('frontend') {
          sh 'npm run build'
        }
      }
    }

    stage('Upload to S3') {
      steps {
        script {
          withAWS(region: 'us-east-1', credentials: 'aws-jenkins') {
            s3Upload(
              //upload build files
              bucket: 'website-bucket-for-audio-test',
              workingDir: 'frontend/build',
              includePathPattern: '**/*'
            )
            // force update of files
            // adding comment to test webhook
            cfInvalidate(distribution: env.CF_DIST_ID, paths: ['/*'])
          }
        }
      }
    }
  }
}


