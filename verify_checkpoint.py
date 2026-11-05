import urllib.request
import json

def check(url, method='GET', payload=None):
    data = json.dumps(payload).encode('utf-8') if payload else None
    headers = {'Content-Type': 'application/json'} if payload else {}
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            content = resp.read().decode('utf-8')
            return resp.status, content
    except Exception as e:
        return 'ERR', str(e)

print('=== 1. ROOT ENDPOINT ===')
st, body = check('https://sentikampus-api.vercel.app/')
print(f'HTTP {st}: {body}')

print('\n=== 2. HEALTH CHECK ===')
st, body = check('https://sentikampus-api.vercel.app/health')
print(f'HTTP {st}: {body}')

print('\n=== 3. PREDICT ENDPOINTS ===')
samples = [
    'Pelayanan kampus sangat bagus dan memuaskan',
    'pelayanan administrasi kampus sangat lambat',
    'pengurusan administrasi di kampus'
]
for text in samples:
    st, resp = check('https://sentikampus-api.vercel.app/api/v1/predict', method='POST', payload={'text': text})
    print(f'Text: "{text}"')
    print(f'HTTP {st}: {resp}')

print('\n=== 4. FRONTEND WEB ===')
st, body = check('https://sentikampus-frontend.vercel.app/')
print(f'HTTP {st}: Reachable ({len(body)} bytes)')
