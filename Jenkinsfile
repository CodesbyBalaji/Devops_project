pipeline {
    agent any
    
    environment {
        AZURE_CREDENTIALS = credentials('azure-service-principal')
        ACR_LOGIN_SERVER = credentials('acr-login-server')
        ACR_USERNAME = credentials('acr-username')
        ACR_PASSWORD = credentials('acr-password')
        IMAGE_NAME = 'vr-campus-viewer'
        IMAGE_TAG = "${BUILD_NUMBER}"
        RESOURCE_GROUP = credentials('azure-resource-group')
        WEB_APP_NAME = credentials('azure-webapp-name')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Verify Prerequisites') {
            steps {
                script {
                    echo 'Verifying required files...'
                    sh '''
                        if [ ! -f "index.html" ]; then
                            echo "ERROR: index.html not found!"
                            exit 1
                        fi
                        if [ ! -f "Dockerfile" ]; then
                            echo "ERROR: Dockerfile not found!"
                            exit 1
                        fi
                        echo "All required files present."
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh """
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    echo 'Testing Docker image...'
                    sh """
                        docker run -d --name test-container -p 8888:80 ${IMAGE_NAME}:${IMAGE_TAG}
                        sleep 5
                        
                        if docker ps | grep -q test-container; then
                            echo "Container is running successfully"
                            curl -f http://localhost:8888 || exit 1
                        else
                            echo "Container failed to start"
                            exit 1
                        fi
                        
                        docker stop test-container
                        docker rm test-container
                    """
                }
            }
        }
        
        stage('Push to Azure Container Registry') {
            steps {
                script {
                    echo "Pushing image to ACR: ${ACR_LOGIN_SERVER}"
                    sh """
                        echo ${ACR_PASSWORD} | docker login ${ACR_LOGIN_SERVER} -u ${ACR_USERNAME} --password-stdin
                        
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest
                        
                        docker push ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest
                        
                        docker logout ${ACR_LOGIN_SERVER}
                    """
                }
            }
        }
        
        stage('Deploy to Azure App Service') {
            steps {
                script {
                    echo "Deploying to Azure App Service: ${WEB_APP_NAME}"
                    sh """
                        az login --service-principal \
                            -u \${AZURE_CREDENTIALS_USR} \
                            -p \${AZURE_CREDENTIALS_PSW} \
                            --tenant \${AZURE_CREDENTIALS_TENANT}
                        
                        az webapp config container set \
                            --name ${WEB_APP_NAME} \
                            --resource-group ${RESOURCE_GROUP} \
                            --docker-custom-image-name ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG} \
                            --docker-registry-server-url https://${ACR_LOGIN_SERVER} \
                            --docker-registry-server-user ${ACR_USERNAME} \
                            --docker-registry-server-password ${ACR_PASSWORD}
                        
                        az webapp restart \
                            --name ${WEB_APP_NAME} \
                            --resource-group ${RESOURCE_GROUP}
                        
                        az logout
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo 'Performing health check...'
                    sh """
                        sleep 30
                        
                        APP_URL=\$(az webapp show \
                            --name ${WEB_APP_NAME} \
                            --resource-group ${RESOURCE_GROUP} \
                            --query defaultHostName -o tsv)
                        
                        echo "Checking https://\${APP_URL}"
                        curl -f -k https://\${APP_URL} || exit 1
                        echo "Application is healthy!"
                    """
                }
            }
        }
    }
    
    post {
        always {
            sh """
                docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                docker rmi ${IMAGE_NAME}:latest || true
                docker rmi ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG} || true
                docker rmi ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest || true
            """
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
