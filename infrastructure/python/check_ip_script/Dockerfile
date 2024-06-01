# Use the latest alpine variant of the official Python image from the Docker Hub
FROM python:alpine

# Set the working directory
WORKDIR /app

# Install required Python packages and any additional dependencies
RUN apk add --no-cache --virtual .build-deps gcc musl-dev \
    && pip install --no-cache-dir requests \
    && apk del .build-deps

# Copy the Python script into the container
COPY check_ip_reputation.py .

# Run the script
CMD ["python", "check_ip_reputation.py"]
