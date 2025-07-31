
# Dockerfile to build one of the server images

# Base image
FROM ubuntu:22.04

# Update and install dependencies
RUN apt-get update && apt-get install -y

# Copy code into container
COPY ./app /app

# Set working directory
WORKDIR /app