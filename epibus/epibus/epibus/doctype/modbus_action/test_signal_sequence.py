# Background job to test signals with delays
import time
import frappe

def test_signal_sequence(connection, signal_names, current_index):
    """
    Test signals one at a time with 4-second delays

    Args:
        connection: Modbus Connection name
        signal_names: List of signal names to test
        current_index: Current position in the list
    """
    if current_index >= len(signal_names):
        # All done
        frappe.log("Signal diagnostic test completed")
        return

    signal_name = signal_names[current_index]

    try:
        # Get connection and signal
        conn = frappe.get_doc("Modbus Connection", connection)
        signal = None
        for sig in conn.signals:
            if sig.name == signal_name:
                signal = sig
                break

        if not signal:
            frappe.log(f"Signal {signal_name} not found")
            # Continue to next
            frappe.enqueue(
                "epibus.epibus.doctype.modbus_action.test_signal_sequence.test_signal_sequence",
                connection=connection,
                signal_names=signal_names,
                current_index=current_index + 1,
                queue="short"
            )
            return

        # Determine test value
        if signal.signal_type == "Digital Output Coil":
            test_value = True
            reset_value = False
        else:
            test_value = 100
            reset_value = 0

        # Read initial
        initial_value = signal.read_signal()
        frappe.log(f"Testing {signal.signal_name} (was {initial_value})")

        # Write HIGH
        signal.write_signal(test_value)
        read_back = signal.read_signal()
        frappe.log(f"  Set to {test_value}, read back {read_back}")

        # Wait 4 seconds
        time.sleep(4)

        # Reset
        signal.write_signal(reset_value)
        final_value = signal.read_signal()
        frappe.log(f"  Reset to {reset_value}, final {final_value}")

        # Check success
        if signal.signal_type == "Digital Output Coil":
            write_ok = (read_back == test_value)
            reset_ok = (final_value == reset_value)
        else:
            write_ok = (abs(read_back - test_value) < 2)
            reset_ok = (abs(final_value - reset_value) < 2)

        status = "PASS" if (write_ok and reset_ok) else "FAIL"
        frappe.log(f"  Result: {status} (write={write_ok}, reset={reset_ok})")

    except Exception as e:
        frappe.log(f"Error testing {signal_name}: {str(e)}")

    # Schedule next signal
    frappe.enqueue(
        "epibus.epibus.doctype.modbus_action.test_signal_sequence.test_signal_sequence",
        connection=connection,
        signal_names=signal_names,
        current_index=current_index + 1,
        queue="short"
    )
