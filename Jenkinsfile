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
                        # Parse Azure Service Principal JSON
                        CLIENT_ID=\$(echo '${AZURE_CREDENTIALS}' | python3 -c "import sys, json; print(json.load(sys.stdin)['clientId'])")
                        CLIENT_SECRET=\$(echo '${AZURE_CREDENTIALS}' | python3 -c "import sys, json; print(json.load(sys.stdin)['clientSecret'])")
                        TENANT_ID=\$(echo '${AZURE_CREDENTIALS}' | python3 -c "import sys, json; print(json.load(sys.stdin)['tenantId'])")
                        
                        # Login to Azure
                        az login --service-principal \
                            -u "\${CLIENT_ID}" \
                            -p "\${CLIENT_SECRET}" \
                            --tenant "\${TENANT_ID}"
                        
                        # Update Web App container configuration
                        az webapp config container set \
                            --name ${WEB_APP_NAME} \
                            --resource-group ${RESOURCE_GROUP} \
                            --docker-custom-image-name ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG} \
                            --docker-registry-server-url https://${ACR_LOGIN_SERVER} \
                            --docker-registry-server-user ${ACR_USERNAME} \
                            --docker-registry-server-password ${ACR_PASSWORD}
                        
                        # Restart Web App
                        az webapp restart \
                            --name ${WEB_APP_NAME} \
                            --resource-group ${RESOURCE_GROUP}
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo 'Performing health check...'
                    sh """
                        # Wait for container to start (Azure Web App needs time to pull image and start container)
                        echo "Waiting 60 seconds for container to initialize..."
                        sleep 60
                        
                        APP_URL=\$(az webapp show \
                            --name ${WEB_APP_NAME} \
                            --resource-group ${RESOURCE_GROUP} \
                            --query defaultHostName -o tsv)
                        
                        echo "Starting health check for https://\${APP_URL}"
                        
                        # Retry health check up to 5 times with 10-second intervals
                        MAX_RETRIES=5
                        RETRY_COUNT=0
                        SUCCESS=false
                        
                        while [ \$RETRY_COUNT -lt \$MAX_RETRIES ]; do
                            echo "Health check attempt \$((RETRY_COUNT + 1)) of \$MAX_RETRIES..."
                            
                            # Use -f to fail on HTTP errors, -s for silent, -I for headers only
                            if curl -f -s -I -k https://\${APP_URL} | grep -q "HTTP.*200"; then
                                echo "✅ Health check passed! Application is responding with HTTP 200"
                                SUCCESS=true
                                break
                            else
                                echo "⏳ Application not ready yet, waiting 10 seconds..."
                                sleep 10
                                RETRY_COUNT=\$((RETRY_COUNT + 1))
                            fi
                        done
                        
                        if [ "\$SUCCESS" = "false" ]; then
                            echo "❌ Health check failed after \$MAX_RETRIES attempts"
                            az logout
                            exit 1
                        fi
                        
                        echo "🎉 Application is healthy and serving traffic!"
                        
                        # Logout from Azure after health check
                        az logout
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

