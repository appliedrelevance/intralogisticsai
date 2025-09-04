#!/usr/bin/env python3

import sys
print("Python path:")
for p in sys.path[:5]:
    print(f"  {p}")

try:
    import epibus
    print("✅ epibus import worked")
    print("epibus location:", epibus.__file__ if hasattr(epibus, '__file__') else 'No __file__ attr')
    print("epibus attributes:", [x for x in dir(epibus) if not x.startswith('_')][:10])
except Exception as e:
    print("❌ epibus import failed:", e)

# Try different import paths
paths_to_try = [
    "epibus.install",
    "epibus.epibus.install", 
    "epibus.install.after_install",
    "epibus.epibus.install.after_install"
]

for path in paths_to_try:
    try:
        parts = path.split('.')
        module = __import__(path)
        for part in parts[1:]:
            module = getattr(module, part)
        print(f"✅ SUCCESS: {path} - {module}")
    except Exception as e:
        print(f"❌ FAILED: {path} - {e}")