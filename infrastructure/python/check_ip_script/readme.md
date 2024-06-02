# IP Reputation Script

### Welcome

**This setup uses Docker Compose to build and run the containerized**  
**Python application. The API key is passed to the container via an**  
**environment variable, ensuring it remains secure and configurable.**

### API Keys & Other parameters 
## Getting IPQualityScore API Key

Signup for an account at **ipqualityscore.com** (free account gives you 5000 lookups per month currently)  
Then go to: https://www.ipqualityscore.com/user/settings  
**API Key** is located under API Key, directly below Email.

## Getting AbuseIPDB API Key

Signup for an account at: **https://www.abuseipdb.com/** (free account gives you 1000 checks per day currently)  
Then go to: https://www.abuseipdb.com/account/api  
Create key and insert into your variable.

## Volume
Logs volume:  ./logs:/app/logs


### Setup instructions:

## Docker Image

Grab the image jcunix/projects:ip_rep_checker
docker pull jcunix/projects:ip_rep_checker

## Docker-Compose.yml
<pre>version: '3.8'

services:
  ip_reputation_checker:
    build: .
    container_name: ip_reputation_checker
    environment:
      - IPQUALITYSCORE_API_KEY=${IPQUALITYSCORE_API_KEY}
      - ABUSEIPDB_API_KEY=${ABUSEIPDB_API_KEY}
      - PORT=${PORT}
      - TEXT_COLOR=${TEXT_COLOR}
      - BACKGROUND_COLOR=${BACKGROUND_COLOR}
    volumes:
      - ./logs:/app/logs
    ports:
      - "${PORT}:${PORT}" </pre>

# .env file:
<pre>IPQUALITYSCORE_API_KEY=your_ipqualityscore_api_key  
ABUSEIPDB_API_KEY=your_abuseipdb_api_key  
PORT=5000  
TEXT_COLOR=#000000  
BACKGROUND_COLOR=#FFFFFF </pre>

# structure
<pre>/project-directory  
├── Dockerfile  
├── docker-compose.yml  
├── .env  
├── check_ip_reputation.py  
└── static  
   └── styles.css </pre>

# execute
docker-compose up --build



### Disclaimer

>The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.

>The user acknowledges that the use of the software is at their own risk. The authors and copyright holders disclaim any responsibility for any harm, damage, or loss that may occur as a result of using the software. The user agrees to hold the authors and copyright holders harmless from any claims, liabilities, or costs arising from their use of the software.
