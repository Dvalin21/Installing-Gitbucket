#!/bin/bash

# Function to check and install default-jre
install_java() {
    if ! dpkg -s default-jre &> /dev/null; then
        echo "default-jre is not installed. Installing..."
        sudo apt update
        sudo apt install -y default-jre
    else
        echo "default-jre is already installed."
    fi
}

# Function to pull the latest GitBucket version
update_gitbucket() {
    local gitbucket_dir="/opt/gitbucket"
    local gitbucket_war="$gitbucket_dir/gitbucket.war"
    
    # Create GitBucket directory if it doesn't exist
    mkdir -p "$gitbucket_dir"
    
    # Check if an older version exists
    if [ -f "$gitbucket_war" ]; then
        read -p "An existing GitBucket version found. Do you want to keep it? (y/n): " keep_old
        if [[ $keep_old =~ ^[Nn]$ ]]; then
            rm "$gitbucket_war"
            echo "Old version deleted."
        else
            echo "Keeping the old version."
            return
        fi
    fi
    
    # Pull the latest version
    echo "Downloading the latest GitBucket version..."
    wget -O "$gitbucket_war" https://github.com/gitbucket/gitbucket/releases/latest/download/gitbucket.war
    
    if [ $? -eq 0 ]; then
        echo "GitBucket successfully updated."
    else
        echo "Failed to download GitBucket."
        exit 1
    fi
}

# Function to set up crontab
setup_crontab() {
    local cron_job="@reboot sleep 60 && java -jar /opt/gitbucket/gitbucket.war"
    
    # Check if the cron job already exists
    if ! crontab -l | grep -q "java -jar /opt/gitbucket/gitbucket.war"; then
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        echo "Crontab entry added to run GitBucket after reboot."
    else
        echo "Crontab entry for GitBucket already exists."
    fi
}

# Main script execution
install_java
update_gitbucket
setup_crontab

echo "Setup complete. GitBucket will start automatically after the next reboot."
