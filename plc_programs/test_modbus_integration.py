#!/usr/bin/env python3
"""
Test script for Intralogistics Lab MODBUS integration
Tests ERP integration with CODESYS project via MODBUS TCP
"""

import time
import sys
from pymodbus.client import ModbusTcpClient
from pymodbus.exceptions import ModbusIOException

class IntralogisticsLabTester:
    def __init__(self, host='localhost', port=502):
        self.host = host
        self.port = port
        self.client = ModbusTcpClient(host, port)
        
    def connect(self):
        """Connect to MODBUS server"""
        print(f"🔌 Connecting to MODBUS server at {self.host}:{self.port}")
        if self.client.connect():
            print("✅ Connected successfully")
            return True
        else:
            print("❌ Connection failed")
            return False
            
    def disconnect(self):
        """Disconnect from MODBUS server"""
        self.client.close()
        print("🔌 Disconnected")
        
    def test_system_status(self):
        """Test system status monitoring"""
        print("\n📊 Testing System Status...")
        try:
            # Read system status (registers 100-105)
            result = self.client.read_holding_registers(100, 6)
            if not result.isError():
                print(f"   System State: {result.registers[0]}")
                print(f"   Conveyors Running: {result.registers[1]}")
                print(f"   Robot State: {result.registers[2]}")
                print(f"   RFID1 Status: {result.registers[3]}")
                print(f"   RFID2 Status: {result.registers[4]}")
                print(f"   Safety Status: {result.registers[5]}")
                return True
            else:
                print(f"❌ Error reading status: {result}")
                return False
        except Exception as e:
            print(f"❌ Exception: {e}")
            return False
            
    def test_bin_selection(self):
        """Test bin selection control"""
        print("\n📦 Testing Bin Selection...")
        try:
            # Test selecting bins 1, 5, and 8 (coils 2000, 2004, 2007)
            test_bins = [1, 5, 8]
            
            for bin_num in test_bins:
                coil_address = 2000 + bin_num - 1  # Bin 1 = coil 2000, etc.
                print(f"   Selecting Bin {bin_num} (coil {coil_address})")
                result = self.client.write_coil(coil_address, True)
                if result.isError():
                    print(f"❌ Error selecting bin {bin_num}: {result}")
                    return False
                time.sleep(0.5)
                
            # Read back bin status
            result = self.client.read_coils(2000, 12)
            if not result.isError():
                selected_bins = [i+1 for i, status in enumerate(result.bits[:12]) if status]
                print(f"   Selected bins: {selected_bins}")
                return True
            else:
                print(f"❌ Error reading bin status: {result}")
                return False
                
        except Exception as e:
            print(f"❌ Exception: {e}")
            return False
            
    def test_station_routing(self):
        """Test station routing control"""
        print("\n🎯 Testing Station Routing...")
        try:
            # Test routing: Assembly=1, Receiving=2, Warehouse=3
            stations = ["Assembly", "Receiving", "Warehouse"]
            
            for i, station in enumerate(stations, 1):
                print(f"   Setting route to {station} (coil {2019 + i})")
                # Clear all routing coils first
                for j in range(4):
                    self.client.write_coil(2020 + j, False)
                # Set the desired station
                result = self.client.write_coil(2019 + i, True)
                if result.isError():
                    print(f"❌ Error setting route to {station}: {result}")
                    return False
                time.sleep(0.5)
                
            return True
            
        except Exception as e:
            print(f"❌ Exception: {e}")
            return False
            
    def test_conveyor_monitoring(self):
        """Test conveyor status monitoring"""
        print("\n🏭 Testing Conveyor Monitoring...")
        try:
            # Read conveyor status (registers 300-307)
            result = self.client.read_holding_registers(300, 8)
            if not result.isError():
                for i in range(4):
                    status = result.registers[i]
                    speed = result.registers[i + 4]
                    print(f"   Conveyor {i+1}: Status={status}, Speed={speed}%")
                return True
            else:
                print(f"❌ Error reading conveyor status: {result}")
                return False
                
        except Exception as e:
            print(f"❌ Exception: {e}")
            return False
            
    def test_rfid_data(self):
        """Test RFID data reading"""
        print("\n🏷️  Testing RFID Data...")
        try:
            # Read RFID data (registers 200-205)
            result = self.client.read_holding_registers(200, 6)
            if not result.isError():
                print(f"   RFID1 Tag ID: {result.registers[0]}")
                print(f"   RFID1 Status: {result.registers[1]}")
                print(f"   RFID1 Last Read: {result.registers[2]}")
                print(f"   RFID2 Tag ID: {result.registers[3]}")
                print(f"   RFID2 Status: {result.registers[4]}")
                print(f"   RFID2 Last Read: {result.registers[5]}")
                return True
            else:
                print(f"❌ Error reading RFID data: {result}")
                return False
                
        except Exception as e:
            print(f"❌ Exception: {e}")
            return False
            
    def run_full_test(self):
        """Run complete test suite"""
        print("🧪 Intralogistics Lab MODBUS Integration Test")
        print("=" * 50)
        
        if not self.connect():
            return False
            
        tests = [
            self.test_system_status,
            self.test_bin_selection, 
            self.test_station_routing,
            self.test_conveyor_monitoring,
            self.test_rfid_data
        ]
        
        passed = 0
        total = len(tests)
        
        for test in tests:
            if test():
                passed += 1
                print("✅ PASSED")
            else:
                print("❌ FAILED")
                
        print(f"\n📊 Test Results: {passed}/{total} tests passed")
        
        if passed == total:
            print("🎉 All tests passed! MODBUS integration is working correctly.")
        else:
            print("⚠️  Some tests failed. Check CODESYS project and MODBUS server.")
            
        self.disconnect()
        return passed == total

def main():
    """Main test function"""
    if len(sys.argv) > 1:
        host = sys.argv[1]
    else:
        host = 'localhost'
        
    tester = IntralogisticsLabTester(host)
    success = tester.run_full_test()
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()