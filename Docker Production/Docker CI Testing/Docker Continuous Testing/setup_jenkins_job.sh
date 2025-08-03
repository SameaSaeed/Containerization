#!/bin/bash

echo "=== Jenkins Job Setup Instructions ==="
echo ""
echo "1. Open Jenkins at http://localhost:8080"
echo "2. Use the initial admin password shown above"
echo "3. Install suggested plugins"
echo "4. Create admin user"
echo "5. Create a new Pipeline job:"
echo "   - Click 'New Item'"
echo "   - Enter name: 'Selenium-Docker-Tests'"
echo "   - Select 'Pipeline'"
echo "   - Click 'OK'"
echo ""
echo "6. In the job configuration:"
echo "   - Under 'Pipeline', select 'Pipeline script from SCM'"
echo "   - SCM: Git"
echo "   - Repository URL: (your git repository URL)"
echo "   - Script Path: Jenkinsfile"
echo ""
echo "7. Required Jenkins Plugins:"
echo "   - Docker Pipeline"
echo "   - HTML Publisher"
echo "   - JUnit"
echo "   - Pipeline"
echo ""
echo "8. Save and run the job!"
echo ""
echo "=== Manual Jenkins Job Creation ==="
echo "If you prefer to create the job manually:"
echo ""

# Create a basic Jenkins job XML
cat > jenkins_job_config.xml << 'JOBEOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Automated Selenium tests running in Docker containers</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.92">
    <script>
pipeline {
    agent any
    
    stages {
        stage('Setup') {
            steps {
                echo 'Setting up Selenium Grid...'
                sh 'docker-compose up -d selenium-hub chrome-node'
                sh 'sleep 30'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'pytest tests/ -v --html=reports/test_report.html'
            }
        }
        
        stage('Reports') {
            steps {
                archiveArtifacts artifacts: 'reports/**/*'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'reports',
                    reportFiles: 'test_report.html',
                    reportName: 'Test Report'
                ])
            }
        }
    }
    
    post {
        always {
            sh 'docker-compose down'
        }
    }
}
    </script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
JOBEOF

echo "Job configuration XML created: jenkins_job_config.xml"
echo "You can import this into Jenkins if needed."