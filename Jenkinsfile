pipeline {
  agent none

  environment {
    AWS_REGION     = 'us-west-2'
    ECR_REPO_NAME  = 'lesson-5-app'
    GIT_BRANCH     = 'main'
    GIT_CREDS_ID   = ''
    IMAGE_TAG      = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
  }

  stages {

    stage('Prepare') {
      agent {
        kubernetes {
          label 'kubectl-git'
          defaultContainer 'git'
        }
      }
      steps {
        container('git') {
          script {
            env.AWS_ACCOUNT_ID = sh(
              script: 'aws sts get-caller-identity --query Account --output text',
              returnStdout: true
            ).trim()
            env.ECR_REPO = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO_NAME}"
            echo "ECR репозиторій: ${env.ECR_REPO}"
            echo "Тег образу: ${env.IMAGE_TAG}"
          }
        }
      }
    }

    stage('Build & Push Docker Image') {
      agent {
        kubernetes {
          label 'kaniko'
          defaultContainer 'kaniko'
        }
      }
      steps {
        container('kaniko') {
          sh """
            /kaniko/executor \
              --context=dir://\${WORKSPACE} \
              --dockerfile=\${WORKSPACE}/Dockerfile \
              --destination=\${ECR_REPO}:\${IMAGE_TAG} \
              --destination=\${ECR_REPO}:latest \
              --cache=true \
              --cache-repo=\${ECR_REPO}/cache \
              --snapshot-mode=redo \
              --log-format=text
          """
        }
      }
      post {
        success {
          echo "Образ успішно зібрано та запушено: ${env.ECR_REPO}:${env.IMAGE_TAG}"
        }
      }
    }

    stage('Update Helm Chart Image Tag') {
      agent {
        kubernetes {
          label 'kubectl-git'
          defaultContainer 'git'
        }
      }
      steps {
        container('git') {
          withCredentials([
            usernamePassword(
              credentialsId: env.GIT_CREDS_ID,
              usernameVariable: 'GIT_USER',
              passwordVariable: 'GIT_TOKEN'
            )
          ]) {
            sh """
              # Налаштовуємо git identity для комміту
              git config --global user.email "jenkins@ci.local"
              git config --global user.name "Jenkins CI"

              # Клонуємо репозиторій з токеном для аутентифікації
              git clone https://\${GIT_USER}:\${GIT_TOKEN}@\$(echo \${GIT_URL} | sed 's|https://||') repo
              cd repo

              # Перевіряємо поточний тег перед зміною
              echo "Поточний тег:"
              grep 'tag:' charts/django-app/values.yaml

              # Оновлюємо image.tag у values.yaml
              sed -i 's|tag: ".*"|tag: "${IMAGE_TAG}"|' charts/django-app/values.yaml

              echo "Новий тег:"
              grep 'tag:' charts/django-app/values.yaml

              # Комітуємо та пушимо зміни
              git add charts/django-app/values.yaml
              git commit -m "ci: update django-app image tag to ${IMAGE_TAG} [skip ci]"
              git push origin ${GIT_BRANCH}
            """
          }
        }
      }
      post {
        success {
          echo "values.yaml оновлено. Argo CD автоматично синхронізує зміни."
        }
      }
    }

  }

  post {
    success {
      echo """
        Pipeline завершено успішно!
        Образ: \${ECR_REPO}:\${IMAGE_TAG}
        Argo CD підхопить зміни та оновить Django застосунок у кластері.
      """
    }
    failure {
      echo "Pipeline завершився з помилкою. Перевірте логи вище."
    }
  }
}
