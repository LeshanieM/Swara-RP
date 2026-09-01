import os

directory = r'c:\Users\kevin\Downloads\Swara-RP\mobile\lib\features\concomitant\presentation\screens'

for filename in os.listdir(directory):
    if filename.endswith('.dart'):
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if 'package:swara/core/theme/app_theme.dart' not in content:
            lines = content.split('\n')
            last_import_idx = -1
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    last_import_idx = i
            
            if last_import_idx != -1:
                lines.insert(last_import_idx + 1, "import 'package:swara/core/theme/app_theme.dart';")
            else:
                lines.insert(0, "import 'package:swara/core/theme/app_theme.dart';")
                
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write('\n'.join(lines))
            print(f'Added import to {filename}')
