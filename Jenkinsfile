pipeline {
    agent any

    environment {
        ECR_REGISTRY   = '123456789012.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REGION     = 'us-east-1'
        IMAGE_NAME     = 'myapp'
        EKS_CLUSTER    = 'my-eks-cluster'
        HELM_CHART_DIR = 'chart/myapp'
        HELM_RELEASE   = 'myapp'
        HELM_NAMESPACE = 'production'
    }

    parameters {
        booleanParam(
            name: 'DEPLOY',
            defaultValue: false,
            description: 'Deploy to cluster (false = dry-run only)'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_SHORT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG     = "${env.GIT_SHORT_SHA}-${env.BUILD_NUMBER}"
                    env.FULL_IMAGE    = "${env.ECR_REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    echo "Building image: ${env.FULL_IMAGE}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('app') {
                    sh 'npm ci'
                }
            }
        }

        stage('Lint & Test') {
            steps {
                dir('app') {
                    sh 'npm test'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${env.FULL_IMAGE} ."
                sh "docker tag ${env.FULL_IMAGE} ${env.ECR_REGISTRY}/${env.IMAGE_NAME}:${env.GIT_SHORT_SHA}"
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh """
                    trivy image \
                      --exit-code 1 \
                      --severity HIGH,CRITICAL \
                      --no-progress \
                      --format table \
                      ${env.FULL_IMAGE}
                """
            }
        }

        stage('ECR Login & Push') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh """
                        aws ecr get-login-password --region ${env.ECR_REGION} \
                            | docker login --username AWS --password-stdin ${env.ECR_REGISTRY}
                        docker push ${env.FULL_IMAGE}
                        docker push ${env.ECR_REGISTRY}/${env.IMAGE_NAME}:${env.GIT_SHORT_SHA}
                    """
                }
            }
        }

        stage('Helm Validate') {
            steps {
                sh "helm lint ${env.HELM_CHART_DIR}"
                sh """
                    helm template ${env.HELM_RELEASE} ${env.HELM_CHART_DIR} \
                      --set image.repository=${env.ECR_REGISTRY}/${env.IMAGE_NAME} \
                      --set image.tag=${env.IMAGE_TAG}
                """
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        def dryRunFlag = params.DEPLOY ? '' : '--dry-run'
                        sh """
                            aws eks update-kubeconfig \
                              --region ${env.ECR_REGION} \
                              --name ${env.EKS_CLUSTER}

                            helm upgrade --install ${env.HELM_RELEASE} ${env.HELM_CHART_DIR} \
                              --namespace ${env.HELM_NAMESPACE} \
                              --create-namespace \
                              --set image.repository=${env.ECR_REGISTRY}/${env.IMAGE_NAME} \
                              --set image.tag=${env.IMAGE_TAG} \
                              --atomic \
                              --timeout 5m \
                              --wait \
                              ${dryRunFlag}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker image prune -f || true'
        }
        success {
            echo "Built and ${params.DEPLOY ? 'deployed' : 'dry-run validated'}: ${env.FULL_IMAGE}"
        }
        failure {
            echo "Build ${env.BUILD_NUMBER} failed."
        }
    }
}
