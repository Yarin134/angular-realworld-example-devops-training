import org.jenkinsci.plugins.docker.workflow.DockerBuildImage

String PUSHED_TAG
Map<String, DockerBuildImage> images_and_tags = [:]
final String DOCKER_CREDENTIALS = 'yarin-dockerhub'

def getRepoUrlWithCreds(String repoUrl, String credentialsId) {
    def urlWithCreds = ''

    withCredentials([
        usernamePassword(
            credentialsId: credentialsId,
            usernameVariable: 'GIT_USERNAME',
            passwordVariable: 'GIT_PASSWORD'
        )
    ]) {
        return repoUrl.replaceFirst(/(https?:\/\/)/, "\$1${GIT_USERNAME}:${GIT_PASSWORD}@")
    }
}

pipeline {
    agent any

    stages {
        stage("Build") {
            steps {
                script {
                    final String DOCKER_REPO = 'devops-yarin'

                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        List<String> tags = []
                        String version = readJSON(file: 'package.json').version
                        if(env.BRANCH_NAME == 'master') {                            
                            tags.push(version)

                        } else if(env.BRANCH_NAME.startsWith('release')) {
                            tags.addAll(["latest-dev", "release-${env.BUILD_NUMBER}"])
                        } else {
                            tags.push(env.BUILD_NUMBER)
                        }

                        tags.each{ tag -> 
                            images_and_tags.put(tag, docker.build("${DOCKER_USERNAME}/${DOCKER_REPO}:$tag"))
                        }
                    }
                }
            }
        }
        stage("Push") {
            steps {
                script {
                    final String DOCKER_REGISTRY = 'https://index.docker.io/v1/'

                    images_and_tags.each { key, value -> 
                        boolean is_branch_name_master = env.BRANCH_NAME == 'master'
                        boolean is_release_divide_four = key.startsWith('release') && (key.split("-")[1] as Integer) % 4 == 0

                        if(is_branch_name_master || is_release_divide_four) {
                            PUSHED_TAG = key
                            docker.withRegistry(DOCKER_REGISTRY, DOCKER_CREDENTIALS) {
                                value.push()
                            }
                        }
                    }
                }
            }
        }
        stage("Upgrade Helm Charts") {
            steps {
                script {
                    final String VALUES_FILE_PATH = 'values.yaml'
                    final String GIT_CREDENTIALS = 'git_credentials'
                    final String GIT_EMAIL = 'yarindavid24@gmail.com'
                    final String HELM_CHART_VALUE_PROJECT_NAME = 'realworld'

                    if(env.BRANCH_NAME == 'master') {
                        final String GIT_HELM_CHARTS_REPOSITORY = getRepoUrlWithCreds('https://github.com/Yarin134/fake-helm-charts-yarin-training.git', GIT_CREDENTIALS)
                        
                        sh """
                        git clone --branch main ${GIT_HELM_CHARTS_REPOSITORY}
                        sh "sed -i '/${HELM_CHART_VALUE_PROJECT_NAME}:/{n;s/tag:.*/tag: ${PUSHED_TAG}/;}' ${VALUES_FILE_PATH}"
                        git config --global user.name "${GIT_USERNAME}"
                        git config --global user.email "${GIT_EMAIL}"
                        git remote set-url origin ${GIT_HELM_CHARTS_REPOSITORY}
                        git add ${VALUES_FILE_PATH}
                        git commit -m 'change to tag: ${PUSHED_TAG}'
                        git push
                        """
                    }
                }
            }
        }
    }
}