# Utils functions
. utils.sh

# Create envs vars if don't exist
ENV_FILES=(".env" "nginx/site.template")
utils.check_envs_files "${ENV_FILES[@]}"

# Load environment vars, to use from console, run follow command: 
utils.load_environment 

# Menu options
if [[ "$1" == "up" ]]; then
    utils.printer "Set permissions for jenkins volume"
    mkdir -p $SERVICE_JENKINS_VOLUME_HOST
    chown 1000 $SERVICE_JENKINS_VOLUME_HOST
    utils.printer "Build && start services"
    docker-compose up -d jenkins
elif [[ "$1" == "start" ]]; then
    utils.printer "Start services"
    docker-compose start jenkins
elif [[ "$1" == "restart" ]]; then
    utils.printer "Restart services"
    docker-compose restart jenkins
elif [[ "$1" == "stop" ]]; then
    utils.printer "Stop services"
    docker-compose stop jenkins
elif [[ "$1" == "rm" ]]; then
    if [[ "$2" == "all" ]]; then
        utils.printer "Stop && remove jenkins service"
        docker-compose rm jenkins
    else
        utils.printer "Stop && remove all services"
        docker-compose rm jenkins
    fi
elif [[ "$1" == "bash" ]]; then
    utils.printer "Connect to jenkins bash shell"
    docker-compose exec jenkins bash
elif [[ "$1" == "ps" ]]; then
    utils.printer "Show all running containers"
    docker-compose ps
elif [[ "$1" == "logs" ]]; then
    utils.printer "Showing jenkins logs..."
    if [[ -z "$2" ]]; then
        docker-compose logs -f --tail=30 jenkins
    else
        docker-compose logs -f --tail=$2 jenkins
    fi
elif [[ "$1" == "server.config" ]]; then
    utils.printer "Set nginx configuration..."
    mkdir -p /opt/nginx/config/
    if [[ "$2" == "secure" ]]; then
        cp nginx/site.template.ssl /opt/nginx/config/default.conf
    else
        cp nginx/site.template /opt/nginx/config/default.conf
    fi
    utils.printer "Creating logs files..."
    mkdir -p /opt/nginx/logs/
    touch /opt/nginx/logs/site.access
    touch /opt/nginx/logs/site.error
    if [[ "$2" == "secure" ]]; then
        utils.printer "Stopping nginx machine if it's running..."
        docker-compose stop nginx
        utils.printer "Creating letsencrypt certifications files..."
        docker-compose up certbot
    fi
elif [[ "$1" == "server.start" ]]; then
    utils.printer "Starting nginx machine..."
    docker-compose up -d nginx
elif [[ "$1" == "server.up" ]]; then
    # Set initial configuration in server for nginx
    bash docker.sh server.config $2
    # Deploying services to remote machine server
    bash docker.sh server.start $2
elif [[ "$1" == "deploy" ]]; then
    # Build && start jenkins service
    bash docker.local.sh up
    # Set server configuration
    bash docker.local.sh server.up $2
    # Starting nginx service
    bash docker.local.sh server.start
else
    utils.printer "Usage: docker.local.sh [build|up|start|restart|stop|mongo|bash|logs n_last_lines|rm|ps]"
    echo -e "up --> Build && restart jenkins service"
    echo -e "start --> Start jenkins service"
    echo -e "restart --> Restart jenkins service"
    echo -e "stop --> Stop jenkins service"
    echo -e "bash --> Connect to jenkins service bash shell"
    echo -e "logs n_last_lines --> Show jenkins server logs; n_last_lines parameter is optional"
    echo -e "rm --> Stop && remove jenkins service"
    echo -e "rm all --> Stop && remove all services"
    echo -e "server.config --> Set nginx configuration service"
    echo -e "server.config secure --> Set nginx configuration service with ssl && create certificates with certbot"
    echo -e "deploy --> Build, config && start services"
    echo -e "deploy secure --> Deploying services with ssl"
fi