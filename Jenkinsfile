/* import shared library */
@Library('shared-library@master')_

pipeline{
          environment{
              IMAGE_NAME = "staticwebsite"
              IMAGE_TAG = "v1.4"
              STAGING = "coulibaltech-staging"
              PRODUCTION = "coulibaltech-production"
              REPOSITORY_NAME = "coulibalytech"

            // Staging EC2
              STAGING_IP = "54.174.43.185"
              STAGING_USER = "ubuntu"
              STAGING_DEPLOY_PATH = "/home/ubuntu/app/staging"
              STAGING_HTTP_PORT = "80" // Port spécifique pour staging

             // Production EC2
              PRODUCTION_IP = "54.173.247.138"
              PRODUCTION_USER = "ubuntu"
              PRODUCTION_DEPLOY_PATH = "/home/ubuntu/app/production"
              PRODUCTION_HTTP_PORT = "80" // Port spécifique pour production

              SSH_CREDENTIALS_ID = "ec2_ssh_credentials"
              DOCKERHUB_CREDENTIALS = 'dockerhub-credentials-id'
          }
          agent none
          stages{
                stage("Build image") {
                    agent any
                    steps{
                        echo "========executing Build image========"
                        script{
                            sh 'docker build -t $REPOSITORY_NAME/$IMAGE_NAME:$IMAGE_TAG .'
                        }
                    }
                    
                }
                stage("Run container based on builded image") {
                    agent any
                    steps{
                        echo "========executing Run container based on builded image========"
                        script{
                            sh '''
                            docker run --name $IMAGE_NAME -d -p 80:80 -e PORT=5000 $REPOSITORY_NAME/$IMAGE_NAME:$IMAGE_TAG
                            sleep 5

                                '''
                        }
                    }
                    
                }
                stage("Test image") {
                    agent any
                    steps{
                        echo "========executing Test image========"
                        script{
                            sh 'curl http://localhost: | grep -q "Dimension"'
                        }
                    }
                    
                }

                stage("Login to Docker Hub Registry") {
                    agent any      
                    steps {
                            script {
                                echo "Connexion au registre Docker hub"
                            withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                                sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                           }
                       }
                    }

                }

                stage('Push Image in docker hub') {
                        agent any
                        steps {
                            script {
                                echo "Pousser l'image Docker vers le registre..."
                                sh "docker push ${REPOSITORY_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"
                                sh "docker logout"      
                            }
                        }
                    }
                 
               stage("Clean container") {
                  agent any
                  steps{
                      echo "========executing Clean container========"
                      script{
                        sh '''
                        docker stop ${IMAGE_NAME}
                        docker rm -f ${IMAGE_NAME}
                          '''
                       }
                   }
                  
                }
            
                stage("Deploy in staging") {
                  when{
                      expression {GIT_BRANCH == 'origin/master'}
                    }
                  agent any
            
                  steps{
                      echo "========executing Deploy in staging========"
                      
                      script{
                            sshagent (credentials: ['ec2_ssh_credentials']) {
                                echo "Uploading Docker image to Staging EC2"
                               sh """
                               # defining remote commands
                               remote_cmds="
                               docker pull ${REPOSITORY_NAME}/${IMAGE_NAME}:${IMAGE_TAG} &&
                               docker rm -f staging_${IMAGE_NAME} || true && 
                               docker run --name staging_${IMAGE_NAME} -d -p 80:${STAGING_HTTP_PORT} -e PORT=${STAGING_HTTP_PORT} ${REPOSITORY_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
                               "
                               # executing remote commands
                               ssh -o StrictHostKeyChecking=no ${STAGING_USER}@${STAGING_IP} "\$remote_cmds"
                               """

                            }
                        
                        }
                    }
                }
                stage("Test in staging") {
                    agent any
                    steps{
                        echo "========executing Test staging========"
                        script{
                            sh 'curl http://${STAGING_IP}:80 | grep -q "Dimension"'
                        }
                    }
                    
                }
    
                stage("Deploy in production") {
                  when{
                      expression {GIT_BRANCH == 'origin/master'}
                  }
                  agent any

                  steps{
                      echo "========executing Deploy in production========"
                      
                      script{
                            sshagent (credentials: ['ec2_ssh_credentials']) {
                                echo "Uploading Docker image to Production EC2"
                             sh """
                               # defining remote commands
                               remote_cmds="
                               docker pull ${REPOSITORY_NAME}/${IMAGE_NAME}:${IMAGE_TAG} &&
                               docker rm -f production_${IMAGE_NAME} || true && 
                               docker run --name production_${IMAGE_NAME} -d -p 80:${PRODUCTION_HTTP_PORT} -e PORT=${PRODUCTION_HTTP_PORT} ${REPOSITORY_NAME}/${IMAGE_NAME}:${IMAGE_TAG}
                               "
                               # executing remote commands
                               ssh -o StrictHostKeyChecking=no ${PRODUCTION_USER}@${PRODUCTION_IP} "\$remote_cmds"
                               """

                            }
                        
                        }
                  }
               }
               stage("Test in production") {
                    agent any
                    steps{
                        echo "========executing Test staging========"
                        script{
                            sh 'curl http://${PRODUCTION_IP}:80 | grep -q "Dimension"'
                        }
                    }
                    
                }
               
            }

           post {
                     always { 
                               script {
                                 /* Use slackNotifier.groovy from shared library and provide current build result as parameter*/
                                 slackNotifier currentBuild.result
                               }
                     }
                }


        }
