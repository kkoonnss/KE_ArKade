import json
import os
import re

brain_dir = r"C:\Users\Kons\.gemini\antigravity\brain"
out_path = r"C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\stitched_main.gd"

file_lines = {}

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
                                lines = content.split('\n')
                                parsing = False
                                for l in lines:
                                    if re.match(r'^\d+: ', l):
                                        parsing = True
                                    if parsing:
                                        m = re.match(r'^(\d+): (.*)', l)
                                        if m:
                                            line_num = int(m.group(1))
                                            line_text = m.group(2)
                                            file_lines[line_num] = line_text
                                        elif l.startswith('The above content'):
                                            parsing = False
            except Exception:
                pass

# Also get lines from current corrupted main.gd to fill the end
with open('app/hub/main.gd', 'r', encoding='utf-8') as f:
    corrupted_lines = f.readlines()
    
# From corrupted, lines 54 to 104 map to 1777 to 1827
for i in range(54, len(corrupted_lines)):
    line_text = corrupted_lines[i].rstrip('\n')
    line_num = 1777 + (i - 54)
    file_lines[line_num] = line_text

with open('recover_log.txt', 'w', encoding='utf-8') as f:
    f.write("Total stitched lines: " + str(len(file_lines)) + "\n")
    if len(file_lines) > 0:
        max_line = max(file_lines.keys())
        f.write("Max line number: " + str(max_line) + "\n")
        
    # Check for gaps
    gaps = []
    for i in range(1, max_line + 1):
        if i not in file_lines:
            gaps.append(i)
    f.write("Gaps: " + str(gaps) + "\n")

# Write stitched file
if len(file_lines) > 0:
    max_line = max(file_lines.keys())
    with open(out_path, 'w', encoding='utf-8') as f:
        for i in range(1, max_line + 1):
            f.write(file_lines.get(i, '') + '\n')
