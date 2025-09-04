#!/usr/bin/env python3

try:
    from epibus.epibus.install import complete_setup_wizard
    print("✅ SUCCESS: epibus.epibus.install import worked!")
    print("Function:", complete_setup_wizard)
except ImportError as e:
    print("❌ FAILED: epibus.epibus.install import failed:", e)

try:
    import epibus.epibus.install
    print("✅ SUCCESS: epibus.epibus.install module import worked!")
    print("Module:", epibus.epibus.install)
except ImportError as e:
    print("❌ FAILED: epibus.epibus.install module import failed:", e)

try:
    import epibus
    print("✅ SUCCESS: epibus import worked!")
    print("Available attributes:", dir(epibus))
except ImportError as e:
    print("❌ FAILED: epibus import failed:", e)