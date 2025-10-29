pipeline {pipeline {pipeline {

    agent any

        agent any    agent any

    environment {

        ACR_NAME = 'acrvrcampusviewerdev'        

        RESOURCE_GROUP = 'rg-vr-campus-viewer-dev'

        WEB_APP_NAME = 'app-vr-campus-viewer-dev'    environment {    environment {

        IMAGE_NAME = 'vr-campus-viewer'

        IMAGE_TAG = "v${BUILD_NUMBER}"        // Azure Service Principal credentials (stored in Jenkins)        // Azure credentials stored in Jenkins

        SUBSCRIPTION_ID = '3b193060-7732-4b0d-a8d5-399332a729f0'

        TENANT_ID = '512c852c-3bb5-46d3-a873-98a9c37927b0'        AZURE_CREDENTIALS = credentials('azure-service-principal')        AZURE_CREDENTIALS = credentials('azure-service-principal')

    }

                    

    stages {

        stage('Checkout') {        // Container Registry        // Container Registry (will be set from Terraform output)

            steps {

                echo 'Checking out code from GitHub...'        ACR_NAME = 'acrvrcampusviewerdev'        ACR_LOGIN_SERVER = credentials('acr-login-server')

                checkout scm

            }        ACR_LOGIN_SERVER = "${ACR_NAME}.azurecr.io"        ACR_USERNAME = credentials('acr-username')

        }

                ACR_CREDENTIALS = credentials('acr-credentials')        ACR_PASSWORD = credentials('acr-password')

        stage('Verify Prerequisites') {

            steps {                

                echo 'Verifying Docker installation...'

                sh 'docker --version'        // Azure Resources        // Image details

            }

        }        RESOURCE_GROUP = 'rg-vr-campus-viewer-dev'        IMAGE_NAME = 'vr-campus-viewer'

        

        stage('Build Docker Image') {        WEB_APP_NAME = 'app-vr-campus-viewer-dev'        IMAGE_TAG = "${BUILD_NUMBER}"

            steps {

                echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"                

                script {

                    docker.build("${IMAGE_NAME}:${IMAGE_TAG}")        // Docker Image        // App Service details

                }

            }        IMAGE_NAME = 'vr-campus-viewer'        RESOURCE_GROUP = credentials('azure-resource-group')

        }

                IMAGE_TAG = "${env.BUILD_NUMBER}"        WEB_APP_NAME = credentials('azure-webapp-name')

        stage('Test Docker Image') {

            steps {    }    }

                echo 'Running basic image tests...'

                sh """        

                    docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} nginx -t

                """    stages {    stages {

            }

        }        stage('Checkout') {        stage('Checkout') {

        

        stage('Push to ACR') {            steps {            steps {

            steps {

                echo "Pushing image to Azure Container Registry: ${ACR_NAME}.azurecr.io"                echo 'Checking out source code...'                checkout scm

                script {

                    withCredentials([usernamePassword(                checkout scm            }

                        credentialsId: 'acr-credentials',

                        usernameVariable: 'ACR_USERNAME',            }        }

                        passwordVariable: 'ACR_PASSWORD'

                    )]) {        }        

                        sh """

                            echo \${ACR_PASSWORD} | docker login ${ACR_NAME}.azurecr.io -u \${ACR_USERNAME} --password-stdin                stage('Verify Prerequisites') {

                            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}

                            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:latest        stage('Verify Prerequisites') {            steps {

                            docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}

                            docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:latest            steps {                script {

                        """

                    }                echo 'Verifying Docker and Azure CLI...'                    echo 'Verifying required files...'

                }

            }                sh '''                    sh '''

        }

                            docker --version                        if [ ! -f "index.html" ]; then

        stage('Deploy to Azure Web App') {

            steps {                    az --version                            echo "ERROR: index.html not found!"

                echo "Deploying to Azure Web App: ${WEB_APP_NAME}"

                script {                '''                            exit 1

                    withCredentials([usernamePassword(

                        credentialsId: 'azure-service-principal',            }                        fi

                        usernameVariable: 'AZURE_CLIENT_ID',

                        passwordVariable: 'AZURE_CLIENT_SECRET'        }                        if [ ! -f "Dockerfile" ]; then

                    )]) {

                        sh """                                    echo "ERROR: Dockerfile not found!"

                            az login --service-principal \

                                -u \${AZURE_CLIENT_ID} \        stage('Build Docker Image') {                            exit 1

                                -p \${AZURE_CLIENT_SECRET} \

                                --tenant ${TENANT_ID}            steps {                        fi

                            

                            az account set --subscription ${SUBSCRIPTION_ID}                echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"                        echo "All required files present."

                            

                            az webapp config container set \                sh """                    '''

                                --name ${WEB_APP_NAME} \

                                --resource-group ${RESOURCE_GROUP} \                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .                }

                                --docker-custom-image-name ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}

                                                docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest            }

                            az webapp restart \

                                --name ${WEB_APP_NAME} \                """        }

                                --resource-group ${RESOURCE_GROUP}

                        """            }        

                    }

                }        }        stage('Build Docker Image') {

            }

        }                    steps {

        

        stage('Health Check') {        stage('Test') {                script {

            steps {

                echo 'Waiting for application to start...'            steps {                    echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"

                sleep(time: 30, unit: 'SECONDS')

                script {                echo 'Running tests...'                    sh """

                    def appUrl = "https://${WEB_APP_NAME}.azurewebsites.net"

                    echo "Checking application health at: ${appUrl}"                sh """                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

                    sh """

                        curl -f -s -o /dev/null -w "%{http_code}" ${appUrl} || echo "Health check failed"                    # Basic validation - check if image was created                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest

                    """

                }                    docker images ${IMAGE_NAME}:${IMAGE_TAG}                    """

            }

        }                                    }

        

        stage('Cleanup') {                    # Test container startup            }

            steps {

                echo 'Cleaning up local Docker images...'                    docker run -d --name test-container -p 8080:80 ${IMAGE_NAME}:${IMAGE_TAG}        }

                sh """

                    docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true                    sleep 5        

                    docker rmi ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} || true

                    docker logout ${ACR_NAME}.azurecr.io || true                            stage('Test Docker Image') {

                """

            }                    # Check if container is running            steps {

        }

    }                    docker ps | grep test-container                script {

    

    post {                                        echo 'Testing Docker image...'

        success {

            echo '✅ Pipeline completed successfully!'                    # Test HTTP response                    sh """

            echo "Application URL: https://${WEB_APP_NAME}.azurewebsites.net"

        }                    curl -f http://localhost:8080 || exit 1                        # Run container temporarily to test

        failure {

            echo '❌ Pipeline failed. Check logs for details.'                                            docker run -d --name test-container -p 8888:80 ${IMAGE_NAME}:${IMAGE_TAG}

        }

        always {                    # Cleanup test container                        sleep 5

            echo 'Pipeline execution finished.'

        }                    docker stop test-container                        

    }

}                    docker rm test-container                        # Check if container is running


                """                        if docker ps | grep -q test-container; then

            }                            echo "Container is running successfully"

        }                            curl -f http://localhost:8888 || exit 1

                                else

        stage('Push to ACR') {                            echo "Container failed to start"

            steps {                            exit 1

                echo 'Logging into Azure Container Registry...'                        fi

                sh """                        

                    echo ${ACR_CREDENTIALS_PSW} | docker login ${ACR_LOGIN_SERVER} -u ${ACR_CREDENTIALS_USR} --password-stdin                        # Cleanup

                                            docker stop test-container

                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}                        docker rm test-container

                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest                    """

                                    }

                    docker push ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}            }

                    docker push ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest        }

                """        

            }        stage('Push to Azure Container Registry') {

        }            steps {

                        script {

        stage('Deploy to Azure') {                    echo "Pushing image to ACR: ${ACR_LOGIN_SERVER}"

            steps {                    sh """

                echo 'Deploying to Azure Web App...'                        # Login to ACR

                sh """                        echo ${ACR_PASSWORD} | docker login ${ACR_LOGIN_SERVER} -u ${ACR_USERNAME} --password-stdin

                    # Login to Azure                        

                    az login --service-principal -u \${AZURE_CREDENTIALS_USR} -p \${AZURE_CREDENTIALS_PSW} --tenant \${AZURE_CREDENTIALS_TENANT}                        # Tag image for ACR

                                            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}

                    # Set the subscription                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest

                    az account set --subscription \${AZURE_CREDENTIALS_SUBSCRIPTION}                        

                                            # Push to ACR

                    # Update Web App with new image                        docker push ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}

                    az webapp config container set \\                        docker push ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest

                        --name ${WEB_APP_NAME} \\                        

                        --resource-group ${RESOURCE_GROUP} \\                        # Logout

                        --docker-custom-image-name ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG} \\                        docker logout ${ACR_LOGIN_SERVER}

                        --docker-registry-server-url https://${ACR_LOGIN_SERVER} \\                    """

                        --docker-registry-server-user ${ACR_CREDENTIALS_USR} \\                }

                        --docker-registry-server-password ${ACR_CREDENTIALS_PSW}            }

                            }

                    # Restart the web app        

                    az webapp restart --name ${WEB_APP_NAME} --resource-group ${RESOURCE_GROUP}        stage('Deploy to Azure App Service') {

                """            steps {

            }                script {

        }                    echo "Deploying to Azure App Service: ${WEB_APP_NAME}"

                            sh """

        stage('Health Check') {                        # Login to Azure using Service Principal

            steps {                        az login --service-principal \

                echo 'Performing health check...'                            -u \${AZURE_CREDENTIALS_USR} \

                sh """                            -p \${AZURE_CREDENTIALS_PSW} \

                    # Wait for deployment to complete                            --tenant \${AZURE_CREDENTIALS_TENANT}

                    sleep 30                        

                                            # Configure Web App to use the new image

                    # Get the Web App URL                        az webapp config container set \

                    WEB_APP_URL=\$(az webapp show --name ${WEB_APP_NAME} --resource-group ${RESOURCE_GROUP} --query defaultHostName -o tsv)                            --name ${WEB_APP_NAME} \

                                                --resource-group ${RESOURCE_GROUP} \

                    # Check if the app is responding                            --docker-custom-image-name ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG} \

                    curl -f https://\${WEB_APP_URL} || exit 1                            --docker-registry-server-url https://${ACR_LOGIN_SERVER} \

                                                --docker-registry-server-user ${ACR_USERNAME} \

                    echo "Deployment successful! Application is running at: https://\${WEB_APP_URL}"                            --docker-registry-server-password ${ACR_PASSWORD}

                """                        

            }                        # Restart the web app

        }                        az webapp restart \

    }                            --name ${WEB_APP_NAME} \

                                --resource-group ${RESOURCE_GROUP}

    post {                        

        success {                        # Logout from Azure

            echo 'Pipeline completed successfully!'                        az logout

            sh """                    """

                WEB_APP_URL=\$(az webapp show --name ${WEB_APP_NAME} --resource-group ${RESOURCE_GROUP} --query defaultHostName -o tsv)                }

                echo "Application URL: https://\${WEB_APP_URL}"            }

            """        }

        }        

        failure {        stage('Health Check') {

            echo 'Pipeline failed! Please check the logs.'            steps {

        }                script {

        always {                    echo 'Performing health check...'

            echo 'Cleaning up...'                    sh """

            sh """                        # Wait for app to be ready

                # Cleanup local Docker images to save space                        sleep 30

                docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true                        

                docker rmi ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG} || true                        # Get the app URL

            """                        APP_URL=\$(az webapp show \

        }                            --name ${WEB_APP_NAME} \

    }                            --resource-group ${RESOURCE_GROUP} \

}                            --query defaultHostName -o tsv)

                        
                        # Health check
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
            // Clean up Docker images
            sh """
                docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                docker rmi ${IMAGE_NAME}:latest || true
                docker rmi ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG} || true
                docker rmi ${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest || true
            """
        }
        success {
            echo 'Pipeline completed successfully!'
            // You can add notifications here (email, Slack, etc.)
        }
        failure {
            echo 'Pipeline failed!'
            // You can add failure notifications here
        }
    }
}
