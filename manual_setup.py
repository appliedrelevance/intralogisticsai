#!/usr/bin/env python3
"""Manual setup completion for testing"""

from epibus.epibus.install import complete_setup_wizard

print("Running manual setup completion...")
complete_setup_wizard()
print("Setup completed!")