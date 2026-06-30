import sys

with open("app/hub/main.gd", "r", encoding="utf-8") as f:
    lines = f.readlines()

def print_safe(text):
    sys.stdout.buffer.write((text + "\n").encode('utf-8'))

# Let's print out lines around the level listing/creation
# Let's write them to a temp file first so we can read it easily
output_lines = []
for idx, line in enumerate(lines):
    # include line numbers
    output_lines.append(f"{idx+1}: {line}")

with open("scratch/main_gd_extracted.txt", "w", encoding="utf-8") as out:
    out.writelines(output_lines[400:850])

print("Wrote lines 401 to 850 of app/hub/main.gd to scratch/main_gd_extracted.txt")
