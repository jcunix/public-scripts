# Use the official Python image from the Docker Hub
FROM python

# Set the working directory
WORKDIR /app

# Copy the requirements file (if you have one)
# COPY requirements.txt .

# Install required Python packages
# RUN pip install -r requirements.txt
RUN pip install requests

# Copy the rest of the application code
COPY check_ip_reputation.py .

# Set the environment variable (for demonstration purposes, normally you would set this at runtime)
# ENV IPQUALITYSCORE_API_KEY your_api_key

# Run the script
CMD ["python", "check_ip_reputation.py"]
