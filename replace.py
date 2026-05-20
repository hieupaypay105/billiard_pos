import re

file_path = "lib/src/features/khach_hang/presentation/screens/khach_hang_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

target = """              SizedBox(
                width: 134,
                child: InkWell(
                  onTap: () => _openFilterSheet(context, provider),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.filterBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.authButtonBorder),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: AppColors.authButtonText,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'HIỂN THỊ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            color: AppColors.authButtonText,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),"""

replacement = """              SizedBox(
                width: 134,
                child: InkWell(
                  onTap: () => _openFilterSheet(context, provider),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.all(1), // Gradient border width
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        stops: [0.0, 0.49, 1.0],
                        colors: [
                          AppColors.titleGradientStart, // #FFDBB0
                          AppColors.titleGradientMiddle, // #9C531B
                          AppColors.titleGradientStart, // #FFDBB0
                        ],
                        transform: GradientRotation(0 * math.pi / 180),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.filterBg,
                        borderRadius: BorderRadius.circular(3), // 4 - padding
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: AppColors.authButtonText,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'HIỂN THỊ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                              color: AppColors.authButtonText,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),"""

print("Is target strictly in string?", target in content)

# Instead of strict string, let's just wipe out from 'child: InkWell(' down to '),' after 'HIỂN THỊ' and replace it.

pattern = re.compile(r'              SizedBox\(\s*width: 134,\s*child: InkWell\(\s*onTap: \(\) => _openFilterSheet.*?child: Container\(\s*.*?border: Border\.all\(color: AppColors\.authButtonBorder\),\s*\),\s*child: const Row\(.*?\]\),\s*\),\s*\),\s*\),\s*\),', re.DOTALL)

if pattern.search(content):
    content = pattern.sub(replacement, content)
    print("Replaced with regex!")
else:
    print("Not found with regex either!")

if "import 'dart:math' as math;" not in content:
    content = content.replace("import 'dart:async';", "import 'dart:async';\nimport 'dart:math' as math;")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
