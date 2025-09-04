#!/usr/bin/env python3

try:
    from epibus.install import after_install
    print("✅ SUCCESS: epibus.install.after_install import worked!")
    print("Function:", after_install)
    # Test calling it
    print("Testing function call...")
    after_install()
    print("✅ Function executed successfully!")
except Exception as e:
    print("❌ FAILED:", e)
    import traceback
    traceback.print_exc()