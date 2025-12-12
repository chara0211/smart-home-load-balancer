pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'salmaidoufkir.com'
        KUBERNETES_NAMESPACE = 'smarthome'
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            parallel {
                stage('Build Usage Collector') {
                    steps {
                        dir('usage-collector-service') {
                            sh 'mvn clean compile'
                        }
                    }
                }
                stage('Build Peak Detector') {
                    steps {
                        dir('peak-detector-service') {
                            sh 'mvn clean compile'
                        }
                    }
                }
                stage('Build Device Simulator') {
                    steps {
                        dir('device-simulator-service') {
                            sh 'mvn clean compile'
                        }
                    }
                }
                stage('Build Optimizer') {
                    steps {
                        dir('optimizer-service') {
                            sh 'mvn clean compile'
                        }
                    }
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Test Usage Collector') {
                    steps {
                        dir('usage-collector-service') {
                            sh 'mvn test'
                        }
                    }
                }
                stage('Test Peak Detector') {
                    steps {
                        dir('peak-detector-service') {
                            sh 'mvn test'
                        }
                    }
                }
                stage('Test Device Simulator') {
                    steps {
                        dir('device-simulator-service') {
                            sh 'mvn test'
                        }
                    }
                }
                stage('Test Optimizer') {
                    steps {
                        dir('optimizer-service') {
                            sh 'mvn test'
                        }
                    }
                }
            }
        }
        
        stage('Package Docker Images') {
            steps {
                script {
                    def services = [
                        'usage-collector-service',
                        'peak-detector-service',
                        'device-simulator-service',
                        'optimizer-service'
                    ]
                    
                    services.each { service ->
                        dir(service) {
                            def imageTag = "${DOCKER_REGISTRY}/${service}:${env.BUILD_NUMBER}"
                            def latestTag = "${DOCKER_REGISTRY}/${service}:latest"
                            
                            sh """
                                docker build -t ${imageTag} .
                                docker build -t ${latestTag} .
                                docker push ${imageTag}
                                docker push ${latestTag}
                            """
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def services = [
                        'usage-collector-service',
                        'peak-detector-service',
                        'device-simulator-service',
                        'optimizer-service'
                    ]
                    
                    services.each { service ->
                        sh """
                            kubectl set image deployment/${service} \
                                ${service}=${DOCKER_REGISTRY}/${service}:${env.BUILD_NUMBER} \
                                -n ${KUBERNETES_NAMESPACE}
                            kubectl rollout status deployment/${service} -n ${KUBERNETES_NAMESPACE}
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}

