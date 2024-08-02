import requests
import json

webHookUrl = "http://localhost/fmerest/v3/automations/workflows/46f3c86c-1ecb-4c7d-a8c0-3a88571724c9/b1e0142c-27b8-114f-be48-62a96672893d/message"

data = {}

r = requests.post(webHookUrl, data=json.dumps(data), headers={'Content-Type': 'application/json'})

r