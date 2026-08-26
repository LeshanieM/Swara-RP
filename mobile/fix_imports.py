import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace ../../../core with package:swara/core
    content = re.sub(r"import\s+['\"](?:\.\./)+core/([^'\"]+)['\"];", r"import 'package:swara/core/\1';", content)
    
    # Specific fixes
    content = content.replace("import '../../data/providers/therapy_provider.dart';", "import 'package:swara/features/therapy/data/providers/therapy_provider.dart';")
    content = content.replace("import '../../../child/data/models/demo_data.dart';", "import 'package:swara/features/child/data/models/demo_data.dart';")
    content = content.replace("import '../../data/providers/child_provider.dart';", "import 'package:swara/features/child/data/providers/child_provider.dart';")
    content = content.replace("import '../../child/data/models/demo_data.dart';", "import 'package:swara/features/child/data/models/demo_data.dart';")
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                fix_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
