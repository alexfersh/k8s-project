pipeline {

  environment {
    RABBITMQ_REGISTRY = 'bitnami/rabbitmq'
    CONSUMER_REGISTRY = 'alexfersh/consumer'
    PRODUCER_REGISTRY = 'alexfersh/producer'
    HELM_REPO = 'https://charts.bitnami.com/bitnami'
  }

  options {
    ansiColor('xterm')
  }

  agent {
    kubernetes {
      defaultContainer 'jnlp'
      yamlFile 'builder.yaml'
    }
  }

  stages {
    stage('Deploy RabbitMQ App to Kubernetes') {     
      steps {
        container('helm') {
          withCredentials([file(credentialsId: 'mykubeconfig', variable: 'KUBECONFIG')]) {
            sh '''
            chmod +x ./deploy_rabbitmq.sh
            sh ./deploy_rabbitmq.sh
            '''
          }
        }
      }
    }
    stage('Build application images with Kaniko and push them into DockerHub public repository') {
      parallel {
        stage('Kaniko - build & push Producer app image') {
          steps {
            container('kaniko-1') {
              script {
                sh '''
                /kaniko/executor --context `pwd`/producer \
                                 --dockerfile `pwd`/producer/Dockerfile \
                                 --destination=$PRODUCER_REGISTRY:${BUILD_NUMBER} \
                                 --destination=$PRODUCER_REGISTRY:latest \
                                 --cleanup
                '''
              }
            }
          }
        }
        stage('Kaniko - build & push Consumer app image') {
          steps {
            container('kaniko-2') {
              script {
                sh '''
                /kaniko/executor --context `pwd`/consumer \
                                 --dockerfile `pwd`/consumer/Dockerfile \
                                 --destination=$CONSUMER_REGISTRY:${BUILD_NUMBER} \
                                 --destination=$CONSUMER_REGISTRY:latest \
                                 --cleanup
                '''
              }
            }
          }
        }
      }
    }
    stage('Deploy Producer and Consumer Apps to Kubernetes') {     
      steps {
        container('helm') {
          withCredentials([file(credentialsId: 'mykubeconfig', variable: 'KUBECONFIG')]) {
            sh '''
            sed -i "s/<TAG>/${BUILD_NUMBER}/" ./helm/templates/producer-deployment.yaml
            sed -i "s/<TAG>/${BUILD_NUMBER}/" ./helm/templates/consumer-deployment.yaml
            chmod +x ./deploy_apps.sh
            sh ./deploy_apps.sh
            ''' 
          }
        }
      }
    }
  }

}