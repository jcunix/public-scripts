This setup uses Docker Compose to build and run the containerized Python application. The API key is passed to the container via an environment variable, ensuring it remains secure and configurable.


Setup instructions:

Set the environment variable for your API key:
export IPQUALITYSCORE_API_KEY=your_api_key

Build the Docker image:
docker-compose build

Run the Docker container:
docker-compose up
