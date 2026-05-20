import re

file_path = "lib/src/features/khach_hang/presentation/screens/khach_hang_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "width: 134" in line:
        start = max(0, i - 1)
        # print 50 lines around it
        for j in range(start, min(len(lines), start + 40)):
            print(repr(lines[j]))
        break
