import json

try:
    with open('european_youth_projects.json', 'r', encoding='utf-8') as f:
        p = json.load(f)
    print(f'Projects collected: {p.get("projectCount", 0)}')
    print(f'First project: {p["projects"][0]["title"] if p["projects"] else "none"}')
except FileNotFoundError:
    print('File not found')
except Exception as e:
    print(f'Error: {e}')
