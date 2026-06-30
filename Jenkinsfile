pipeline {
    agent {
        docker {
            image 'maven:3.9.15-amazoncorretto-21'
        }
    }
    environment {
        MAVEN_OPTS = "-Dmaven.repo.local=${WORKSPACE}/.m2"
        SONAR_USER_HOME = "${WORKSPACE}/.sonar"
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean compile -B -ntp'
            }
        }
        stage('Test Junit') {
            steps {
                sh 'mvn test -B -ntp'
            }
            post { 
                success {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        stage('Test Jacoco') {
            steps {
                sh 'mvn jacoco:report -B -ntp'
            }
            post { 
                success {
                    recordCoverage(tools: [[parser: 'JACOCO']])
                }
            }
        }
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests -B -ntp'
            }
        }
        stage('SonarQube') {
            steps {
                withSonarQubeEnv('sonarqube'){
                    script {
                        if (env.CHANGE_ID) {
                            sh """
                                mvn sonar:sonar -B -ntp \
                                -Dsonar.pullrequest.key=${env.CHANGE_ID} \
                                -Dsonar.pullrequest.branch=${env.CHANGE_BRANCH} \
                                -Dsonar.pullrequest.base=${env.CHANGE_TARGET}
                            """
                        } else {
                            def branchName = GIT_BRANCH.replaceFirst('^origin/', '')
                            println "Branch name: ${branchName}"
                            sh "mvn sonar:sonar -B -ntp -Dsonar.branch.name=${branchName} -Dsonar.branch.target=${branchName}"
                        }
                    }
                }
            }
        }
        stage('DockerHub') {
            agent {
                docker {
                    image 'docker:29.4.0-cli'
                    args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            environment {
                DOCKER_CONFIG = "${WORKSPACE}/.docker"
                DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
            }            
            options { skipDefaultCheckout() }
            steps {
                script {

                    def pom = readMavenPom file: 'pom.xml'
                    def image = "danycenas/${pom.artifactId}"
                    
                    sh 'docker run --privileged --rm tonistiigi/binfmt --install all'
                    sh 'docker buildx create --use'
                    sh 'docker buildx inspect --bootstrap'

                    sh 'docker buildx version'

                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                        sh """
                            docker buildx build \
                                -t ${image}:${pom.version} \
                                -t ${image}:latest \
                                --platform linux/amd64,linux/arm64 --push .
                        """
                    }
                }
            }
        }            
    }
    post { 
        success {
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
        cleanup {
            cleanWs()
        }
    }
}