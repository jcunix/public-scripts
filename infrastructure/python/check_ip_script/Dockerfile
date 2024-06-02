# Use the latest alpine variant of the official Python image from the Docker Hub
FROM python:alpine

# Provide basic author information and labels
LABEL maintainer=jcunix 

# Set the working directory
WORKDIR /app

# Install required Python packages and any additional dependencies
RUN apk add --no-cache --virtual .build-deps gcc musl-dev \
    && apk add --no-cache libffi-dev openssl-dev \
    && pip install --no-cache-dir requests dnspython flask apscheduler \
    && apk del .build-deps

# Copy the Python script and static files into the container
COPY check_ip_reputation.py .
COPY static /app/static

# Run the script
CMD ["python", "check_ip_reputation.py"]