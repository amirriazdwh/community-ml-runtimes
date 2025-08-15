import requests
from requests.exceptions import SSLError, ProxyError, ConnectionError, Timeout, RequestException

url = "https://mcr.microsoft.com"
proxies = {
    "http":  "http://your-proxy:port",
    "https": "http://your-proxy:port"
}
verify_cert_path = "/etc/ssl/certs/ca-certificates.crt"  # or custom proxy CA

try:
    response = requests.get(
        url,
        proxies=proxies,
        verify=verify_cert_path,  # or False to bypass SSL (testing only)
        timeout=10,
        allow_redirects=False     # to detect 302 directly
    )

    # Check for 302 redirect
    if response.status_code == 302:
        print(f"🔁 302 Redirect: {response.headers.get('Location')}")
        print("➡️ Likely redirected by proxy to login or block page.")
    elif response.status_code == 200:
        print("✅ Success! TLS + proxy + DNS all working.")
    else:
        print(f"⚠️ Unexpected status code: {response.status_code}")
        print(response.text[:300])  # Preview any block message

except SSLError as e:
    print("❌ SSL Error: Certificate verification failed.")
    print("🔎 Possible cause: Proxy TLS interception or untrusted cert.")
    print(e)

except ProxyError as e:
    print("❌ Proxy Error: Unable to reach proxy.")
    print("🔎 Possible cause: Proxy misconfigured, auth failed, or proxy host down.")
    print(e)

except ConnectionError as e:
    print("❌ Connection Error: Network or DNS failure.")
    print("🔎 Possible cause: DNS resolution failed, firewall block, or bad endpoint.")
    print(e)

except Timeout:
    print("⏱️ Request timed out.")
    print("🔎 Possible cause: Proxy or server too slow or unreachable.")

except RequestException as e:
    print("❌ Unknown Requests error.")
    print(e)
