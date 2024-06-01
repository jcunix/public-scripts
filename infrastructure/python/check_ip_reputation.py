import os
import requests

# Get the current IP address
def get_current_ip():
    response = requests.get("https://ipinfo.io/json")
    data = response.json()
    return data['ip']

# Check IP reputation
def check_ip_reputation(ip, api_key):
    url = f"https://ipqualityscore.com/api/json/ip/{api_key}/{ip}"
    response = requests.get(url)
    return response.json()

def main():
    # Get API key from environment variable
    api_key = os.getenv("IPQUALITYSCORE_API_KEY")
    
    if not api_key:
        print("Error: API key not found. Please set the IPQUALITYSCORE_API_KEY environment variable.")
        return
    
    # Get current IP address
    current_ip = get_current_ip()
    print(f"Current IP: {current_ip}")
    
    # Get IP reputation
    reputation = check_ip_reputation(current_ip, api_key)
    
    # Print the reputation status
    if reputation['success']:
        print(f"Reputation Status for IP {current_ip}:")
        print(f"Fraud Score: {reputation['fraud_score']}")
        print(f"ISP: {reputation['ISP']}")
        print(f"Organization: {reputation['organization']}")
        print(f"Country: {reputation['country_code']}")
        print(f"Region: {reputation['region']}")
        print(f"City: {reputation['city']}")
        print(f"Usage Type: {reputation['usage_type']}")
        print(f"Risk Status: {'High Risk' if reputation['fraud_score'] > 75 else 'Low Risk'}")
    else:
        print(f"Error checking IP reputation: {reputation['message']}")

if __name__ == "__main__":
    main()
