import os, json

brain_dir = r"C:\Users\Kons\.gemini\antigravity\brain"
transcripts = []
for root, dirs, files in os.walk(brain_dir):
    for f in files:
        if f == "transcript_full.jsonl":
            transcripts.append(os.path.join(root, f))

print(f"Found {len(transcripts)} transcript files.")

for t in transcripts:
    with open(t, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            if 'app/hub/main.gd' in line:
                try:
                    data = json.loads(line)
                    if data.get('type') == 'PLANNER_RESPONSE':
                        for tc in data.get('tool_calls', []):
                            args = tc.get('args', {})
                            if isinstance(args, str):
                                continue
                            target = args.get('TargetFile', '') or args.get('AbsolutePath', '')
                            if 'main.gd' in target and 'app/hub' in target:
                                if tc['name'] == 'write_to_file':
                                    content = args.get('CodeContent', '')
                                    if len(content) > 1000:
                                        print(f"FOUND write_to_file in {t} step {data.get('step_index')}, length: {len(content)}")
                                        
                                if tc['name'] == 'replace_file_content' or tc['name'] == 'multi_replace_file_content':
                                    chunks = args.get('ReplacementChunks', [])
                                    for c in chunks:
                                        repl = c.get('ReplacementContent', '')
                                        if len(repl) > 2000:
                                            print(f"FOUND huge replace chunk in {t} step {data.get('step_index')}, length: {len(repl)}")
                except Exception as e:
                    pass
