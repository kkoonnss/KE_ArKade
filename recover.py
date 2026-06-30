import json
import re

transcript_path = r"C:\Users\Kons\.gemini\antigravity\brain\5dd8f37c-3830-4801-9ac0-389f758d01ea\.system_generated\logs\transcript_full.jsonl"
out_path = r"C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\recovered_main.gd"

highest_lines = 0
best_content = ""

try:
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            data = json.loads(line)
            if data.get('type') == 'VIEW_FILE' or (data.get('type') == 'PLANNER_RESPONSE' and 'cat app/hub/main.gd' in str(data)):
                content = data.get('content', '')
                if 'file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/app/hub/main.gd' in content:
                    # check if this is the full file
                    if 'Showing lines 1 to 1827' in content or 'Showing lines 1 to' in content:
                        best_content = content
                        break
                        
            # Also check tool_calls if agent wrote the whole file
            if data.get('type') == 'PLANNER_RESPONSE':
                for tc in data.get('tool_calls', []):
                    if tc['name'] == 'write_to_file' and 'app/hub/main.gd' in tc['args'].get('TargetFile', ''):
                        c = tc['args'].get('CodeContent', '')
                        if len(c.split('\n')) > highest_lines:
                            highest_lines = len(c.split('\n'))
                            best_content = c
                            
except Exception as e:
    print(e)

with open('recover_log.txt', 'w', encoding='utf-8') as f:
    f.write("Best content length: " + str(len(best_content)) + "\n")
    if best_content:
        f.write(best_content[:1000])

if best_content:
    # clean up view_file formatting
    if 'The following code has been modified' in best_content:
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
