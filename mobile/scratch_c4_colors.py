import os
import re

directories = [
    r'c:\Users\kevin\Downloads\Swara-RP\mobile\lib\components\component4\screens',
    r'c:\Users\kevin\Downloads\Swara-RP\mobile\lib\components\component4\widgets'
]

replacements = {
    r'Colors\.orange': 'AppColors.primary',
    r'Colors\.blue\.shade50': 'AppColors.primaryWash',
    r'Colors\.blue\.shade100': 'AppColors.primaryWash',
    r'Colors\.blue\.shade300': 'AppColors.primaryLight',
    r'Colors\.blue\.withOpacity\([^)]*\)': 'AppColors.primaryWash',
    r'Colors\.blue': 'AppColors.primary',
    r'Colors\.green': 'AppColors.success',
    r'Colors\.red\.shade300': 'AppColors.error',
    r'Colors\.red\.shade400': 'AppColors.error',
    r'Colors\.redAccent\.shade100': 'AppColors.error',
    r'Colors\.grey\.shade300': 'AppColors.divider',
    r'Colors\.grey': 'AppColors.textLight',
    r'Colors\.black87': 'AppColors.text',
    r'Colors\.black54': 'AppColors.textLight',
    r'Colors\.black\.withOpacity\([^)]*\)': 'AppColors.divider',
    r'Colors\.white': 'AppColors.white',
    r'const Color\(0xFFF43F5E\)': 'AppColors.error',
    r'Color\(0xFFF43F5E\)': 'AppColors.error',
    r'const Color\(0xFF4ADE80\)': 'AppColors.success',
    r'Color\(0xFF4ADE80\)': 'AppColors.success',
    r'const Color\(0xFF4ADE80\)\.withOpacity\(0\.5\)': 'AppColors.success',
    r'Colors\.red': 'AppColors.error',
}

for directory in directories:
    for filename in os.listdir(directory):
        if filename.endswith('.dart'):
            filepath = os.path.join(directory, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Ensure app_theme is imported
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
                content = '\n'.join(lines)
            
            for pattern, replacement in replacements.items():
                content = re.sub(pattern, replacement, content)
                
            if content != original_content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f'Updated {filename}')
fix: added