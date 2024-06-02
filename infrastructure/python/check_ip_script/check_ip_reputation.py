# 
# Check IP Reputation script
# By Jonathan Wilson, https://github.com/jcunix/ansible/tree/main/infrastructure/python/check_ip_script
# Mozilla Public License Version 2.0 (MPL-2.0)
# jcunix + gmail.com
# 
# 

import os
import requests
import dns.resolver
import logging
from logging.handlers import TimedRotatingFileHandler
from flask import Flask, render_template_string
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime

app = Flask(__name__)

# Set up logging
log_dir = "/app/logs"
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, "ip_reputation.log")
logger = logging.getLogger("IPReputationLogger")
logger.setLevel(logging.INFO)
handler = TimedRotatingFileHandler(log_file, when="midnight", interval=1, backupCount=30)
formatter = logging.Formatter("%(asctime)s - %(message)s")
handler.setFormatter(formatter)
logger.addHandler(handler)

# Global variables to store the latest data
latest_data = {
    "current_ip": "N/A",
    "fraud_score": "N/A",
    "abuseipdb_status": "N/A",
    "spamhaus_listed": "N/A",
    "last_refresh": "N/A"
}

# Function to get the current IP address
def get_current_ip():
    response = requests.get("https://ipinfo.io/json")
    data = response.json()
    return data['ip']

# Function to check IP reputation using IPQualityScore
def check_ip_reputation(ip, api_key):
    url = f"https://ipqualityscore.com/api/json/ip/{api_key}/{ip}"
    response = requests.get(url)
    return response.json()

# Function to check if the IP is on any blocklists using AbuseIPDB
def check_ip_blocklist_abuseipdb(ip, api_key):
    url = f"https://api.abuseipdb.com/api/v2/check"
    headers = {
        'Accept': 'application/json',
        'Key': api_key
    }
    params = {
        'ipAddress': ip,
        'maxAgeInDays': 90  # Check reports within the last 90 days
    }
    response = requests.get(url, headers=headers, params=params)
    return response.json()

# Function to check if the IP is on any blocklists using Spamhaus
def check_ip_blocklist_spamhaus(ip):
    try:
        reverse_ip = '.'.join(reversed(ip.split('.')))
        query = f"{reverse_ip}.zen.spamhaus.org"
        answers = dns.resolver.resolve(query, 'A')
        for answer in answers:
            if answer.address.startswith('127.0.0.'):
                return True
    except dns.resolver.NXDOMAIN:
        return False
    except Exception as e:
        logger.error(f"Error checking Spamhaus: {e}")
        return False
    return False

# Function to perform the periodic polling
def poll_data():
    global latest_data
    ipqualityscore_api_key = os.getenv("IPQUALITYSCORE_API_KEY")
    abuseipdb_api_key = os.getenv("ABUSEIPDB_API_KEY")

    if not ipqualityscore_api_key or not abuseipdb_api_key:
        logger.error("API keys not found. Please set the IPQUALITYSCORE_API_KEY and ABUSEIPDB_API_KEY environment variables.")
        return

    current_ip = get_current_ip()
    reputation = check_ip_reputation(current_ip, ipqualityscore_api_key)
    fraud_score = reputation.get('fraud_score', 'N/A')
    blocklist_info_abuseipdb = check_ip_blocklist_abuseipdb(current_ip, abuseipdb_api_key)
    abuseipdb_status = 'Listed' if blocklist_info_abuseipdb.get('data', {}).get('abuseConfidenceScore', 0) > 0 else 'Not Listed'
    spamhaus_listed = check_ip_blocklist_spamhaus(current_ip)

    latest_data = {
        "current_ip": current_ip,
        "fraud_score": fraud_score,
        "abuseipdb_status": abuseipdb_status,
        "spamhaus_listed": 'Listed' if spamhaus_listed else 'Not Listed',
        "last_refresh": datetime.utcnow().strftime('%Y-%m-%d')
    }

    logger.info(f"Current IP: {current_ip}, Fraud Score: {fraud_score}, AbuseIPDB Status: {abuseipdb_status}, Spamhaus Status: {'Listed' if spamhaus_listed else 'Not Listed'}")

@app.route('/')
def index():
    text_color = os.getenv("TEXT_COLOR", "#000000")  # Default to black if not provided
    background_color = os.getenv("BACKGROUND_COLOR", "#FFFFFF")  # Default to white if not provided
    
    return render_template_string("""
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8" />
    <title>IP Reputation and Blocklist Status</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta content="jcunix" name="author" />
    <link rel="stylesheet" type="text/css" href="{{ url_for('static', filename='tailwind.css') }}">

    <script src=
"https://cdnjs.cloudflare.com/ajax/libs/jquery/3.4.0/jquery.min.js">
    </script>

 <style>
        body {
            transition: background-color 0.3s, color 0.3s;
        text-align:center;
        color: #017bff;
        }
        img{
            height:140px;
                width:140px; 
        }
        h1{
        color: #017bff;
        }
        .change {
            cursor: pointer;
            border: 0px solid #555;
            border-radius: 0%;
            width: 10px;
            text-align: center;
            padding: 1px;
            margin-left: 0px;
            color: #019bf0;
        }
        .dark{
            background-color: #222;
            color: #017bff;
        }
    </style>
</head>

<body>

<script>
function launch() { PopW=window.open("{{ url_for('view_logs') }}","Log History","width=900,height=400,top=10,left=20,resizable=yes,scrollbars=yes,menubar=no,toolbar=no,status=yes,location=no") }
</script>
                <div class="shadow-md bg-white rounded-lg h-fit">
                    <div>
                        <div class="overflow-x-auto">
                            <div class="min-w-full inline-block align-middle">
                                <div class="overflow-hidden">
                                    <table class="min-w-full divide-y divide-gray-200">
                                        <thead>
                                            <tr>
                                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Current IP</th>
                                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Reputation Score</th>
                                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">AbuseIPDB Status</th>
                                                <th scope="col" class="px-6 py-3 text-end text-xs font-medium text-gray-500 uppercase">Spamhaus Status</th>
                                            </tr>
                                        </thead>
                                        <tbody class="divide-y divide-gray-200">
                                            <tr class="hover:bg-gray-100">
                                                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-800">{{ data.current_ip }}</td>
                                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-800">{{ data.fraud_score }}</td>
                                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-800">{{ data.abuseipdb_status }}</td>
                                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-800">{{ data.spamhaus_listed }}</td>
                                            </tr>

                                            <tr class="hover:bg-gray-100">

                                            </tr>

                                            <tr class="hover:bg-gray-100">

                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
				<center><span><a href="javascript:launch()">View Logs</a> | Last Refresh:</strong> {{ data.last_refresh }} | Dark mode:             
        <span class="change">OFF</span>
    </span></center>
        
    <script>
        $( ".change" ).on("click", function() {
            if( $( "body" ).hasClass( "dark" )) {
                $( "body" ).removeClass( "dark" );
                $( ".change" ).text( "OFF" );
            } else {
                $( "body" ).addClass( "dark" );
                $( ".change" ).text( "ON" );
            }
        });
    </script>

</body>
    </html>
    """, data=latest_data, text_color=text_color, background_color=background_color)

@app.route('/view_logs')
def view_logs():
    try:
        with open(log_file, 'r') as f:
            log_content = f.read()
        return render_template_string("""
        <html>
            <head><title>IP Reputation Logs</title>
    <script src=
"https://cdnjs.cloudflare.com/ajax/libs/jquery/3.4.0/jquery.min.js">
    </script>
 <style>
        body{
        transition: background-color 0.3s, color 0.3s;
        text-align:center;
        }
        img{
            height:140px;
                width:140px; 
        }
        h1{
        color: #017bff;
        }
        .mode {
            float:right;
        }
        .change {
            cursor: pointer;
            border: 1px solid #555;
            border-radius: 40%;
            width: 20px;
            text-align: center;
            padding: 5px;
            margin-left: 8px;
        }
        .dark{
            background-color: #222;
            color: #e6e6e6;
        }
        a:link {
            color: #017bff; /* Unvisited link color */
        }
        a:visited {
            color: #017bff; /* Visited link color */
        }
        a:hover {
            color: #019bf0; /* Hovered link color */
        }
        a:active {
            color: #017bff; /* Active link color */
        }

    </style>
</head>

<body>
    <div class="mode">
        Dark mode:             
        <span class="change">OFF</span>
    </div>

                <h1>IP Reputation Logs (Last 30 Days)</h1>
                <pre>{{ log_content }}</pre>
                <p>
<button onclick="return closeWindow();">
    Close Window
</button>
</p>
 
<script type="text/javascript">
    function closeWindow() {
 
        // Open the new window 
        // with the URL replacing the
        // current page using the
        // _self value
        let new_window =
            open(location, '_self');
 
        // Close this window
        new_window.close();
 
        return false;
    }
</script>

    <script>
        $( ".change" ).on("click", function() {
            if( $( "body" ).hasClass( "dark" )) {
                $( "body" ).removeClass( "dark" );
                $( ".change" ).text( "OFF" );
            } else {
                $( "body" ).addClass( "dark" );
                $( ".change" ).text( "ON" );
            }
        });
    </script>

            </body>
        </html>
        """, log_content=log_content)
    except Exception as e:
        return str(e)

if __name__ == "__main__":
    # Set up the scheduler to poll data every 24 hours
    scheduler = BackgroundScheduler()
    scheduler.add_job(poll_data, 'interval', hours=24)
    scheduler.start()

    # Perform an initial poll
    poll_data()

    port = int(os.getenv("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
