String PUSHED_TAG
images_and_tags = [:]

pipeline {
    agent any

    stages {
        stage("Build") {
            steps {
                script {
                    final String DOCKER_REPO = 'devops-yarin'
                    final String DOCKER_CREDENTIALS = 'yarin-dockerhub'

                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        tags = []
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
                            docker.withRegistry(DOCKER_REGISTRY, 'yarin-dockerhub') {
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
                    final String GIT_HELM_CHARTS_REPOSITORY = 'https://github.com/Yarin134/fake-helm-charts-yarin-training.git'

                    if(env.BRANCH_NAME == 'master') {
                        git(url: GIT_HELM_CHARTS_REPOSITORY, branch: 'main')
                        sh "sed -i '/realworld:/{n;s/tag:.*/tag: ${PUSHED_TAG}/;}' ${VALUES_FILE_PATH}"
                        withCredentials([usernamePassword(credentialsId: GIT_CREDENTIALS, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                            sh """
                            git config --global user.name "${GIT_USERNAME}"
                            git config --global user.email "${GIT_EMAIL}"
                            git remote set-url origin https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${GIT_USERNAME}/fake-helm-charts-yarin-training.git
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
}