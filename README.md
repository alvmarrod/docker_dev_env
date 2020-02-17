# Development Environment in Docker

This project aims to take the development platform to the next level, leaving behind the need to manually prepare your environment before starting to work.

## Content

The project aims to develop a specific image or Dockerfile for each kind of environment that you may need. Support items like deployment scripts may be available within the same folder.

## Usage

You have two options to use this repo:

1. You can go to [*Docker Hub*](https://hub.docker.com/repository/docker/naipsas/develop/general) and use published images directly.

2. You can use the provided scripts and dockerfiles to build your own images, with some extra capabilities like adding your host files to your image, i.e. `.bashrc` or `.bash_aliases` files. This option is not always available.

If you choose the second option, continue reading the last section please.

### How to

To get ready you only need to clone this repo, and execute the specific script to perform:

1. Docker installation
2. Docker Images build
3. Ready! Run the containers and work with them! 

The script will be specific for each environment, and it relies in different `Dockerfiles` that are at different folders.

### Available Environments

Finally, here we provide a list with the existing environments and their contents, with a pattern like:

> Name - Folder Name - Explanation

1. **Tensorflow on GPU** - `tf_on_gpu` - Includes from CUDA to Keras in order to allow easy Deep Learning development. Refer to [this Medium article](https://medium.com/@alvmarrod/dockerize-your-tensorflow-development-environment-91d6a0120945) for further information.
2. **Go + ReactJS** - `go_reactjs` - Includes Go, Node.js and ReactJS to allow easy Web development with modern technologies. Refer to this Medium article for further information.
3. ...