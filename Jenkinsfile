pipeline {
    agent {
        docker {
            image 'python:3.10-slim'
        }
    }
    stages {
        stage('Install dependencies') {
            steps {
                sh 'pip install --upgrade pip'
                sh 'pip install pyinstaller'
            }
        }
        stage('Build') {
            steps {
                sh 'pyinstaller --onefile your_script.py'
            }
        }
        stage('Test') {
            steps {
                sh 'python -m unittest discover'
            }
        }
    }
}
