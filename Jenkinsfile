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
                sh 'mvn clean package -DskipTests -B -ntp'
            }
        }
        stage('Tests (Junit + Jacoco)') {
            steps {
                sh 'mvn test jacoco:report -B -ntp'
            }
            post {
                success {
                    junit 'target/surefire-reports/*.xml'
                    recordCoverage(tools: [[parser: 'JACOCO']])
                }
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
            agent any
            environment {
                DOCKER_CONFIG = "${WORKSPACE}/.docker"
                DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
            }            
            options { skipDefaultCheckout() }
            steps {
                script {

                    def pom = readMavenPom file: 'pom.xml'
                    def image = "jcharalla/${pom.artifactId}"
                    
                    sh "docker build -t ${image}:${pom.version} . -t ${image}:latest"
                    sh 'docker images'

                    sh 'echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin'
                    sh "docker push ${image}:${pom.version}"
                    sh "docker push ${image}:latest"
                    sh 'docker logout'
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