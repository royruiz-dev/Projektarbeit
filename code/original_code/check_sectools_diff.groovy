#!groovy
 
def rc
 
pipeline {
 
    agent { label 'englobauto' }
 
    stages {
 
        stage('Fetch Sectools Info') {
            steps {
                script {
                    rc = sh(script: "https_proxy='' exec/scripts/sectools_diff.sh > out.json", returnStatus: true)
                }
            }
        }
 
        stage('Sectools Objects List') {
            when {
                expression { rc == 133 }
            }
            steps {
                sh '''set +x
                    echo
                    echo
                    echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                    echo
                    DIFF=$(jq -r ".[] | [.hostname, .not_installed] |
                        select(.[1]) | .[1]|=join(\\",\\") | @tsv" out.json | column -t -o$\'\\t\') # list JSON -> text table
                    if [[ $DIFF ]] ; then
                        echo "Security tools required but NOT installed/activated by host:"
                        echo "---------------------------------------------"
                        echo "$DIFF"
                        echo
                    fi
                    DIFF=$(jq -r ".[] | [.hostname, .not_required] |
                        select(.[1]) | .[1]|=join(\\",\\") | @tsv" out.json | column -t -o$\'\\t\') # list JSON -> text table
                    if [[ $DIFF ]] ; then
                        echo "Security tools installed/activated but NOT required by host:"
                        echo "----------------------------------------------------"
                        echo "$DIFF"
                        echo
                    fi
                    echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                    echo
                    echo
                '''
            }
        }
        stage('Slack Alerts') {
            when {
                expression { rc == 133 }
            }
            steps {
                sh '''
                    jq -r \'["Total number of hosts:", length],
                        ["Hosts with Security Tools installed/activated but NOT required:", (map(select(.not_required)) | length)],
                        ["Hosts with Security Tools required but NOT installed/activated:", (map(select(.not_installed)) | length)] |
                        @tsv\' out.json | column -t -s $\'\\t\' > out.txt
                 
                    if [[ -s out.txt ]] ; then
                        HEAD="Security tools discrepancies detected! <${BUILD_URL}consoleText|Jenkins Job Log>"
                        exec/common/slack "Security Check" :supersafe: "$HEAD" "$(<out.txt)" codeblock          # send slack message
                    fi
                '''
            }
        }
    }
 
    post {
        always {
            script {
                cleanWs()
            }
        }
    }
}