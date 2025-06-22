def FIRST_IMAGE
def SECOND_IMAGE
String FIRST_IMAGE_TAG_NAME
String SECOND_IMAGE_TAG_NAME

String PUSHED_TAG
def images_and_tags = [:] // map declaration

pipeline {
    agent {
        label 'devops-training-yarin'
    }

    environment {
        DOCKER_REPO = 'devops-yarin'
    }

    stages {
        stage("Build") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'yarin-dockerhub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    script {
                        tags = []
                        version = readJSON(file: 'package.json').version
                        if(env.BRANCH_NAME == 'master') {
                            // FIRST_IMAGE_TAG_NAME = version
                            
                            tags.push(version)  // TEST

                        } else if(env.BRANCH_NAME.startsWith('release')) {
                            // FIRST_IMAGE_TAG_NAME = "latest-dev"
                            // SECOND_IMAGE_TAG_NAME = "release-${env.BUILD_NUMBER}"

                            tags.push("latest-dev") // TEST
                            tags.push("release-${env.BUILD_NUMBER}") // TEST

                        } else {
                            // FIRST_IMAGE_TAG_NAME = env.BUILD_NUMBER

                            tags.push(env.BUILD_NUMBER) // TEST
                        }
                        // FIRST_IMAGE = docker.build("${DOCKER_USERNAME}/${DOCKER_REPO}:${FIRST_IMAGE_TAG_NAME}")
                        // SECOND_IMAGE = docker.build("${DOCKER_USERNAME}/${DOCKER_REPO}:${SECOND_IMAGE_TAG_NAME}")

                        tags.each{ tag -> 
                           images_and_tags.put(tag, docker.build("${DOCKER_USERNAME}/${DOCKER_REPO}:$tag"))
                        }


                        sh 'echo YarinDavidTheRalph'
                        images_and_tags.each { key, value -> echo "Key: ${key} , Value: ${value}"}


                    }
                }
            }
        }
        stage("Push") {
            steps {
                script {
                    // shouldPushFirstTagImage = env.BRANCH_NAME == 'master'
                    // shouldPushSecondTagImage = SECOND_IMAGE_TAG_NAME && SECOND_IMAGE_TAG_NAME.startsWith('release') && (
                    // (SECOND_IMAGE_TAG_NAME.split("-")[1] as Integer) % 4 == 0)

                    images_and_tags.each { key, value -> 
                        is_branch_name_master = env.BRANCH_NAME == 'master'
                        is_release_divide_four = key.startsWith('release') && (key.split("-")[1] as Integer) % 4 == 0

                        if(is_branch_name_master || is_release_divide_four) {
                            PUSHED_TAG = key
                            docker.withRegistry('https://index.docker.io/v1/', 'yarin-dockerhub') {
                                value.push()
                            }
                        }
                    }

                    // if (shouldPushFirstTagImage || shouldPushSecondTagImage) {
                    //     docker.withRegistry('https://index.docker.io/v1/', 'yarin-dockerhub') {
                    //         if (shouldPushFirstTagImage) {
                    //             FIRST_IMAGE.push()
                    //         }
                    //         if (shouldPushSecondTagImage) {
                    //             SECOND_IMAGE.push()
                    //         }             
                    //     }
                    // }
                }
            }
        }
        stage("Upgrade Helm Charts") {
            steps {
                script {
                    if(env.BRANCH_NAME == 'master') {
                        git(url: 'https://github.com/Yarin134/fake-helm-charts-yarin-training.git', branch: 'main')
                        sh "sed -i '/realworld:/{n;s/tag:.*/tag: ${PUSHED_TAG}/;}' values.yaml"
                        sh 'cat values.yaml'
                        withCredentials([usernamePassword(credentialsId: 'git_credentials', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                            sh """
                            git config --global user.name "${GIT_USERNAME}"
                            git config --global user.email "yarindavid24@gmail.com"
                            git remote set-url origin https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${GIT_USERNAME}/fake-helm-charts-yarin-training.git
                            git add values.yaml
                            git commit -m 'change to tag: ${PUSHED_TAG} '
                            git push
                            """
                        }
                    }
                }
            }
        }
    }
}