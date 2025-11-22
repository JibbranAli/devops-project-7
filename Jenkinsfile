pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-registry.example.com'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        PATH = "/usr/local/bin:$PATH"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }
        
        stage('Setup Environment') {
            steps {
                echo 'Setting up Python environment...'
                sh '''
                    python --version
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }
        
        stage('Train Models') {
            steps {
                echo 'Training ML models...'
                sh '''
                    python app/train_model.py
                    ls -lh app/models/
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                echo 'Running unit tests...'
                sh '''
                    pip install pytest
                    python -m pytest tests/ -v --tb=short
                '''
            }
        }
        
        stage('Build Docker Images') {
            steps {
                echo 'Building Docker images...'
                sh '''
                    # Build Flask API image
                    docker build -f docker/Dockerfile.api \
                        -t mlops-flask-api:${IMAGE_TAG} \
                        -t mlops-flask-api:latest \
                        .
                    
                    # Build Streamlit UI image
                    docker build -f docker/Dockerfile.streamlit \
                        -t mlops-streamlit-ui:${IMAGE_TAG} \
                        -t mlops-streamlit-ui:latest \
                        .
                    
                    echo "Docker images built successfully"
                    docker images | grep mlops
                '''
            }
        }
        
        stage('Push Images') {
            steps {
                echo 'Pushing Docker images to registry...'
                script {
                    // This stage is optional and can be uncommented when you have a registry
                    echo 'Skipping push - configure DOCKER_REGISTRY to enable'
                    
                    // Uncomment below when registry is configured:
                    /*
                    sh """
                        docker tag mlops-flask-api:${IMAGE_TAG} ${DOCKER_REGISTRY}/mlops-flask-api:${IMAGE_TAG}
                        docker tag mlops-streamlit-ui:${IMAGE_TAG} ${DOCKER_REGISTRY}/mlops-streamlit-ui:${IMAGE_TAG}
                        
                        docker push ${DOCKER_REGISTRY}/mlops-flask-api:${IMAGE_TAG}
                        docker push ${DOCKER_REGISTRY}/mlops-streamlit-ui:${IMAGE_TAG}
                    """
                    */
                }
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying services with Docker Compose...'
                sh '''
                    # Stop existing services (except Jenkins)
                    docker-compose stop flask-api streamlit-ui prometheus || true
                    docker-compose rm -f flask-api streamlit-ui prometheus || true
                    
                    # Start services (excluding Jenkins to avoid stopping ourselves)
                    docker-compose up -d flask-api streamlit-ui prometheus
                    
                    # Wait for services to be healthy
                    echo "Waiting for services to start..."
                    sleep 15
                    
                    # Check service status
                    docker-compose ps
                    
                    echo "Deployment complete!"
                '''
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Performing health checks...'
                sh '''
                    # Check Flask API
                    curl -f http://localhost:5000/health || exit 1
                    
                    # Check Prometheus
                    curl -f http://localhost:9090/-/healthy || exit 1
                    
                    echo "All services are healthy!"
                '''
            }
        }
        
        stage('Smoke Test') {
            steps {
                echo 'Running smoke tests...'
                sh '''
                    # Test prediction endpoint
                    curl -X POST http://localhost:5000/predict \
                        -H "Content-Type: application/json" \
                        -d '{"features": [5.1, 3.5, 1.4, 0.2]}' \
                        | grep -q "prediction"
                    
                    echo "Smoke tests passed!"
                '''
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up...'
            sh '''
                # Archive models
                tar -czf models-${BUILD_NUMBER}.tar.gz app/models/
            '''
            archiveArtifacts artifacts: 'models-*.tar.gz', fingerprint: true
        }
        
        success {
            echo 'Pipeline completed successfully!'
            // Add notifications here (email, Slack, etc.)
        }
        
        failure {
            echo 'Pipeline failed!'
            sh 'docker-compose logs'
            // Add failure notifications here
        }
    }
}
