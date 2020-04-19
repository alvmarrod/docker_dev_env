#!/bin/bash
# Alvaro MR
# This script has been published on Github for a Medium story
apt_silent="-qq -o=Dpkg::Use-Pty=0"
script_path=$(dirname "$0")
script_path=$(readlink -f $script_path)

function read_param {

    printf "Introduce $1 value (Default: $2): "
    read param

    if [ "$param" = "" ]; then
        param="$2"
    fi

}

function ensure_path {

    printf "Introduce your path to $1 to mount (Default: $2): "
    read param

    if [ "$param" = "" ]; then
        param="$2"
    fi

}

function ask_question {

    printf "Do you want to $1 (Default: $2): "
    read param

    if [ "$param" = "" ]; then
        param="$2"
    fi

}

function install {

    printf "NOTICE: that you need NVIDIA GPU Driver already installed!\n"

    printf "Continue? (y/n): "
    read param

    if [ "$param" = "y" ]; then

        printf "\t Installing Docker...\n"
        sudo apt install $apt_silent -y docker-ce

        printf "\t Installing NVIDIA Container Toolkit...\n"
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

        sudo apt $apt_silent update && sudo apt $apt_silent install -y nvidia-container-toolkit
        sudo systemctl restart docker

        sudo apt $apt_silent autoclean

    else
        printf "\t Exitting...\n"
    fi

}

function build {

    # Parameters
    read_param "CUDA" "10.0"
    cuda=$param

    read_param "cuDNN" "7.5.1.10"
    cudnn=$param

    read_param "TF" "1.13.2"
    TF=$param

    # We only ask for Keras if TF major version is minor than 2
    if [ "${TF::1}" = "1" ]; then
        read_param "Keras" "2.2.5"
        Keras=$param
    fi

    printf "Username detected: $USER\n"

    read_param "User ID" "$(id -u)"
    USERID=$param

    if [ ! -d "$script_path/Config/" ]; then
        mkdir $script_path/Config/
    fi

    ask_question "use your host bashrc and bash_aliases files?" "true"
    config_files=$param

    if [ "$config_files" = true ]; then
        cp ~/.bashrc $script_path/Config/
        cp ~/.bash_aliases $script_path/Config/
    fi

    ask_question "use your ssh config and etc/hosts files?" "true"
    config_files=$param

    if [ "$config_files" = true ]; then
        cp ~/.ssh/config $script_path/Config/
        cp /etc/hosts $script_path/Config/
    fi

    # Ask for image name
    printf "Please name your docker image: "
    read dockerfile
    
    # if [ ! -f "./../Dockerfiles/level_3/$dockerfile" ]; then
    if [[ "$(docker images -q $dockerfile 2> /dev/null)" != "" ]]; then
        printf "\tImage exists! Do you want to overwrite it? (y/n): "
        read param
    else
        param="y"
    fi

    if [ "$param" = "y" ]; then

        docker build -t "$dockerfile" \
                --build-arg CUDA=$cuda \
                --build-arg CUDNN=$cudnn \
                --build-arg TF=$TF \
                --build-arg KERAS=$Keras \
                --build-arg USER=$USER \
                --build-arg USERID=$USERID \
                .
        if [ "$?" = "0" ]; then
            printf "\tBUILD of $dockerfile: OK\n"
        else
            printf "\tBUILD of $dockerfile: ERROR\n"
            printf "\tAborting process...\n"
        fi

    else
        printf "Aborting process...\n"
    fi

}

function run {

    # First, look for stopped containers that may be desired to run again
    amount=$(docker ps -f "status=exited" -q | wc -l)
    restart="false"

    if [ $amount -ge 1 ]; then

        ask_question "run a stopped container?" "true"
        restart=$param

    fi
    
    if [ "$restart" = "true" ]; then

        # Show the existing stopped containers to the user
        printf "Currently stopped containers:\n"
        existing=$(docker ps -f "status=exited" --format '{{.Names}} - {{.Image}}  - {{.Status}}')

        index=1
        while IFS= read -r line; do
            printf "\t$index. $line\n"
            index=$[index+1]
        done <<< "$(echo -e "$existing")"

        printf "\n"
        printf "Please choose a container to run it again: "
        read option

        if [ "$option" = "" ]; then
            option=$[amount+1]
        fi

        if [ $option -le $amount ]; then

            containers="$(docker ps -f "status=exited" -q)"

            index=1
            while IFS= read -r line; do
                if [ "$index" = "$option" ]; then
                    containerID="$line"
                fi
                index=$[index+1]
            done <<< "$(echo -e "$containers")"

            printf "\tRunning container with ID: $containerID\n"
            docker start "$containerID"
            printf "\tPlease now use option \"Go into\" to go inside the container!\n"

        else
            printf "\tError! Index out of bounds!"
        fi

    else

        # Not restart an old container, but run a new one
        amount=$(docker images -q | wc -l)

        if [ $amount -ge 1 ]; then

            printf "Images available locally:\n"
            items=$(docker images --format '{{lower .Repository}}')

            index=1
            for i in $items; do
                printf "\t$index. $i\n"
                index=$[index+1]
            done

            printf "\n"
            printf "Please choose an image to execute (create a container): "
            read option

            if [ "$option" = "" ]; then
                option=$[amount+1]
            fi

            if [ $option -le $amount ]; then

                printf "\n"
                printf "Specify a name for the container: "
                read name

                if [ "$name" != "" ]; then
                    name="--name $name"
                fi

                # nvidia-smi --query-gpu=gpu_name,memory.used --format=csv,noheader
                GPUs=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader | wc -l)
                max_index=$[GPUs-1]
                printf "\n"
                printf "You've $GPUs GPUs available from 0 to $max_index\n"
                read_param "GPUs (i.e. 0,1,...)" "$max_index"
                GPUs=$param
                
                GPUs="--gpus \"device=${GPUs}\""

                arr=($items)
                option="${arr[$option-1]}"
                printf "\tExecuting container with image $option\n"

                user=$(ls -l --format=single-column /home/)
                base_path="/home/$user"

                code_path="$base_path/repos"
                dataset_path="$base_path/datasets/"
                videos_path="$base_path/Videos/"

                ensure_path "CODE" $code_path
                code_path=$param
                ensure_path "DATASETS" $dataset_path
                dataset_path=$param
                ensure_path "VIDEOS" $videos_path
                videos_path=$param

                mount_repo="--mount src=$code_path,target=/chroma_tools,type=bind"
                mount_dataset="--mount src=$dataset_path,target=/datasets,type=bind"
                mount_videos="--mount src=$videos_path,target=/videos,type=bind"
                mount_all="$mount_repo $mount_dataset $mount_videos"

                # X11 server Binding
                X11="-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix"
                docker run $X11 $GPUs $mount_all $name -dit "$option"

            else
                printf "\tError! Index out of bounds!"
            fi

        else
            printf "There're no images! Build one first!\n"
        fi

    fi

}

function gointo {

    # Look for running containers
    amount=$(docker container ls -q | wc -l)

    if [ $amount -ge 1 ]; then

        printf "Currently running containers:\n"
        items=$(docker container ls --format '{{.Names}} | {{.Image}} | {{.Status}}')

        index=1
        while IFS= read -r line; do
            printf "\t$index. $line\n"
            index=$[index+1]
        done <<< "$(echo -e "$items")"

        printf "\n"
        printf "Please choose a container to go into it: "
        read option

        if [ "$option" = "" ]; then
            option=$[amount+1]
        fi

        if [ $option -le $amount ]; then

            containers="$(docker container ls -q)"

            index=1
            while IFS= read -r line; do
                if [ "$index" = "$option" ]; then
                    containerID="$line"
                fi
                index=$[index+1]
            done <<< "$(echo -e "$containers")"

            printf "Going into container with ID: $containerID\n"
            # X11 server Binding
            X11="-e DISPLAY=$DISPLAY"
            docker exec $X11 -it "$containerID" /bin/bash

        else
            printf "\tError! Index out of bounds!"
        fi

    else
        printf "There're no running containers! Create one first!\n"
    fi

}

function remove_containers {

    if [ "$1" = "all" ]; then
        printf "\tStopping containers..."
        docker stop $(docker ps -a -q)
        printf "\tRemoving containers..."
        docker rm $(docker container ls -qa)
    else
        printf "\tRemoving stopped containers..."
        docker container prune --force
    fi

}

function remove_images {

    if [ "$1" = "all" ]; then
        docker rmi --force $(docker images -qa)
    else
        docker image prune --force --filter dangling=true
    fi

}

function return_to_menu {

    printf "\n"
    printf "Do you want to go back to the menu? (y/n): "
    read option

    if [ "$option" = "y" ]; then
        clear
        menu
    else
        exit
    fi

}

function menu {

    printf "\n"

    if [ $# -eq 0 ]; then

        printf "###                       ###\n"
        printf "##                         ##\n"
        printf "#  1. Install Docker & Dpc. #\n"
        printf "#  2. Build Docker Image    #\n"
        printf "#  3. Run Docker Container  #\n"
        printf "#  4. Go into Container     #\n"
        printf "#  5. Clean                 #\n"
        printf "#  6. Remove All Containers #\n"
        printf "#  7. Remove All Images     #\n"
        printf "#  8. Exit                  #\n"
        printf "##                         ##\n"
        printf "###                       ###\n"

        printf "\n"
        printf "Select an option: "
        read option

    else
        option="$1"
    fi

    if [ "$option" = "1" ]; then
        install
        return_to_menu
    elif [ "$option" = "2" ]; then
        build
        return_to_menu
    elif [ "$option" = "3" ]; then
        run
        return_to_menu
    elif [ "$option" = "4" ]; then
        gointo
        return_to_menu
    elif [ "$option" = "5" ]; then
        remove_containers
        remove_images
        return_to_menu
    elif [ "$option" = "6" ]; then
        remove_containers "all"
        return_to_menu
    elif [ "$option" = "7" ]; then
        remove_images "all"
        return_to_menu
    elif [ "$option" = "8" ]; then
        printf "\tExitting!\n"
        exit
    else
        printf "\tInvalid option!\n"
        return_to_menu
    fi
}

# Execution depends on two types of arguments. If there's a number, it's
# a menu option. But if it's not, it may be a running command so it should
# be processed differently

if [ $# -gt 0 ]; then
    # Pass all arguments (supposed to be only 1)
    # the menu option number to run
    menu "$1"
else
    menu
fi