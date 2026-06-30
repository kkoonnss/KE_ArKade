import json
import os
import re

brain_dir = r"C:\Users\Kons\.gemini\antigravity\brain"
out_path = r"C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\recovered_main.gd"

highest_lines = 0
best_content = ""

for root, dirs, files in os.walk(brain_dir):
    for f_name in files:
        if f_name == "transcript_full.jsonl":
            path = os.path.join(root, f_name)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    for line in f:
                        data = json.loads(line)
                        content = data.get('content', '')
                        if 'file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/app/hub/main.gd' in content:
                            if 'The following code has been modified' in content:
                                lines_count = len(content.split('\n'))
                                if lines_count > highest_lines:
                                    highest_lines = lines_count
                                    best_content = content
            except Exception:
                pass

with open('recover_log.txt', 'w', encoding='utf-8') as f:
    f.write("Best content lines: " + str(highest_lines) + "\n")

if best_content:
    lines = best_content.split('\n')
    cleaned = []
    parsing = False
    for l in lines:
        if l.startswith('1: '):
            parsing = True
        if parsing:
            if re.match(r'^\d+: ', l):
                cleaned.append(l.split(': ', 1)[1])
            elif l.startswith('The above content'):
                parsing = False
            else:
                cleaned.append(l)
    
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(cleaned))
