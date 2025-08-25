#!/usr/bin/env python3
"""
Simplified PLC Bridge - No complexity, just basic functionality

This replaces the overly complex bridge.py with:
- Simple 3-second polling loop
- No retry logic, no exponential backoff
- No SSE - just HTTP polling
- Basic error handling - if something fails, try again next cycle
"""

import os
import sys
import time
import logging
import threading
import requests
import json
from typing import Dict, List, Union, Optional
from pymodbus.client import ModbusTcpClient
from flask import Flask, Response, jsonify, request
from flask_cors import CORS

class SimplePLCBridge:
    """Dead simple PLC Bridge - no complexity"""
    
    def __init__(self, frappe_url: str, poll_interval: float = 3.0):
        self.frappe_url = frappe_url
        self.poll_interval = poll_interval
        
        # Simple logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
        
        # Current signal values - just a simple dict
        self.current_signals = {}
        self.last_values = {}
        
        # MODBUS connections - just store what we need
        self.connections = {}
        
        # Simple Flask app for the dashboard
        self.app = Flask(__name__)
        CORS(self.app)
        
        # Set up routes
        self.app.route('/')(self.dashboard)
        self.app.route('/signals')(self.get_signals) 
        self.app.route('/write_signal', methods=['POST'])(self.write_signal)
        
        # Control flags
        self.running = False
        self.poll_thread = None
        self.flask_thread = None
    
    def load_signals_from_frappe(self):
        """Load signal definitions from Frappe - simple, no retry logic"""
        try:
            self.logger.info("Loading signals from Frappe...")
            response = requests.get(
                f"{self.frappe_url}/api/method/epibus.api.plc.get_signals",
                headers={'Host': 'intralogistics.lab'},
                timeout=10
            )
            response.raise_for_status()
            data = response.json()
            
            # Handle Frappe's response format
            if 'message' in data:
                if isinstance(data['message'], list):
                    # Direct list format
                    connections_data = data['message']
                elif isinstance(data['message'], dict) and data['message'].get('success') and 'data' in data['message']:
                    # Wrapped format with success/data
                    connections_data = data['message']['data']
                else:
                    self.logger.error(f"Frappe API error: {data['message']}")
                    return False
            else:
                self.logger.error(f"Unexpected response format: {data}")
                return False
            
            # Process connections and signals
            self.connections = {}
            self.current_signals = {}
            
            for conn_data in connections_data:
                conn_name = conn_data['name']
                host = conn_data['host']
                port = conn_data['port']
                
                self.connections[conn_name] = {
                    'host': host,
                    'port': port,
                    'client': None
                }
                
                # Process signals for this connection
                for signal_data in conn_data.get('signals', []):
                    signal_id = signal_data['name']
                    self.current_signals[signal_id] = {
                        'name': signal_id,
                        'signal_name': signal_data['signal_name'],
                        'type': signal_data['signal_type'],
                        'address': signal_data['modbus_address'],
                        'connection': conn_name,
                        'value': None,
                        'timestamp': None
                    }
            
            self.logger.info(f"Loaded {len(self.current_signals)} signals from {len(self.connections)} connections")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to load signals: {e}")
            return False
    
    def get_modbus_client(self, connection_name):
        """Get a MODBUS client - create if needed, no complex retry logic"""
        if connection_name not in self.connections:
            return None
        
        conn = self.connections[connection_name]
        
        # Create client if needed
        if conn['client'] is None:
            conn['client'] = ModbusTcpClient(
                host=conn['host'], 
                port=conn['port'], 
                timeout=5
            )
        
        # Try to connect - if it fails, return None and try next cycle
        try:
            if not conn['client'].is_socket_open():
                if not conn['client'].connect():
                    return None
            return conn['client']
        except:
            return None
    
    def read_signal_value(self, signal):
        """Read a single signal value - simple, no complex error handling"""
        try:
            client = self.get_modbus_client(signal['connection'])
            if client is None:
                return None
            
            address = signal['address']
            signal_type = signal['type']
            
            # Read based on signal type
            if signal_type == "Digital Input Contact":
                result = client.read_discrete_inputs(address=address, count=1)
                if not result.isError():
                    return result.bits[0]
            elif signal_type == "Digital Output Coil":
                result = client.read_coils(address=address, count=1)
                if not result.isError():
                    return result.bits[0]
            elif signal_type == "Input Register":
                result = client.read_input_registers(address=address, count=1)
                if not result.isError():
                    return result.registers[0]
            elif signal_type == "Holding Register":
                result = client.read_holding_registers(address=address, count=1)
                if not result.isError():
                    return result.registers[0]
            
            return None
            
        except Exception as e:
            # Don't log every read error - too noisy
            return None
    
    def send_signal_change_to_frappe(self, signal_id, old_value, new_value):
        """Send signal change to Frappe - simple, no complex retry"""
        try:
            data = {
                'name': signal_id,
                'value': new_value,
                'timestamp': time.time()
            }
            
            response = requests.post(
                f"{self.frappe_url}/api/method/epibus.api.plc.signal_update",
                json=data,
                headers={'Host': 'intralogistics.lab'},
                timeout=5
            )
            
            if response.status_code == 200:
                self.logger.info(f"Sent signal change: {self.current_signals[signal_id]['signal_name']} = {new_value}")
            else:
                self.logger.warning(f"Failed to send signal change: HTTP {response.status_code}")
                
        except Exception as e:
            self.logger.warning(f"Failed to send signal change: {e}")
    
    def polling_loop(self):
        """Simple polling loop - no complexity"""
        self.logger.info("Starting simple polling loop...")
        
        while self.running:
            try:
                # Read all signals
                changes = []
                
                for signal_id, signal in self.current_signals.items():
                    new_value = self.read_signal_value(signal)
                    
                    if new_value is not None:
                        old_value = signal['value']
                        
                        # Check for changes
                        if new_value != old_value:
                            signal['value'] = new_value
                            signal['timestamp'] = time.time()
                            changes.append((signal_id, old_value, new_value))
                            
                            # Send to Frappe
                            self.send_signal_change_to_frappe(signal_id, old_value, new_value)
                
                if changes:
                    self.logger.info(f"Processed {len(changes)} signal changes")
                
                # Sleep and repeat
                time.sleep(self.poll_interval)
                
            except Exception as e:
                self.logger.error(f"Error in polling loop: {e}")
                time.sleep(self.poll_interval)  # Just try again
    
    def start(self):
        """Start the bridge"""
        self.logger.info("Starting Simple PLC Bridge...")
        
        # Load signals from Frappe
        if not self.load_signals_from_frappe():
            self.logger.error("Failed to load signals - cannot start")
            return False
        
        # Start polling thread
        self.running = True
        self.poll_thread = threading.Thread(target=self.polling_loop, daemon=True)
        self.poll_thread.start()
        
        # Start Flask server in separate thread
        self.flask_thread = threading.Thread(
            target=lambda: self.app.run(host='0.0.0.0', port=7654, debug=False, use_reloader=False),
            daemon=True
        )
        self.flask_thread.start()
        
        self.logger.info("Simple PLC Bridge started successfully")
        return True
    
    def stop(self):
        """Stop the bridge"""
        self.logger.info("Stopping Simple PLC Bridge...")
        self.running = False
        
        # Close MODBUS connections
        for conn in self.connections.values():
            if conn['client']:
                try:
                    conn['client'].close()
                except:
                    pass
    
    # ========== FLASK ROUTES ==========
    
    def get_signals(self):
        """API endpoint to get all current signal values"""
        signals_list = []
        for signal in self.current_signals.values():
            signals_list.append({
                'name': signal['name'],
                'signal_name': signal['signal_name'],
                'value': signal['value'],
                'timestamp': signal['timestamp']
            })
        
        return jsonify({'signals': signals_list})
    
    def write_signal(self):
        """API endpoint to write a signal value"""
        try:
            data = request.get_json()
            signal_id = data.get('signal_id')
            value = data.get('value')
            
            if signal_id not in self.current_signals:
                return jsonify({'success': False, 'message': 'Signal not found'}), 404
            
            signal = self.current_signals[signal_id]
            client = self.get_modbus_client(signal['connection'])
            
            if client is None:
                return jsonify({'success': False, 'message': 'Connection failed'}), 500
            
            # Write the signal
            address = signal['address']
            signal_type = signal['type']
            
            try:
                if signal_type == "Digital Output Coil":
                    result = client.write_coil(address, bool(value))
                elif signal_type == "Holding Register":
                    result = client.write_register(address, int(value))
                else:
                    return jsonify({'success': False, 'message': f'Cannot write to {signal_type}'}), 400
                
                if result.isError():
                    return jsonify({'success': False, 'message': f'MODBUS write error: {result}'}), 500
                
                # Update our local copy
                signal['value'] = value
                signal['timestamp'] = time.time()
                
                return jsonify({'success': True, 'message': f'Signal {signal["signal_name"]} updated'})
                
            except Exception as e:
                return jsonify({'success': False, 'message': f'Write failed: {e}'}), 500
            
        except Exception as e:
            return jsonify({'success': False, 'message': f'Request error: {e}'}), 400
    
    def dashboard(self):
        """Simple dashboard - no SSE complexity"""
        html = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Simple PLC Bridge Dashboard</title>
    <style>
        * { box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            margin: 0; padding: 20px;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            color: #2c3e50; line-height: 1.6;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header {
            text-align: center; margin-bottom: 30px; background: white;
            padding: 30px; border-radius: 15px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        .header h1 { margin: 0; color: #2c3e50; font-size: 2.5em; font-weight: 300; }
        .header p { margin: 10px 0 0 0; color: #7f8c8d; font-size: 1.1em; }
        .info {
            background: white; border-radius: 15px; padding: 25px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1); margin-bottom: 30px;
        }
        .signals-grid {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 15px; max-height: 500px; overflow-y: auto;
        }
        .signal {
            display: flex; justify-content: space-between; align-items: center;
            padding: 12px 16px; background: white; border-radius: 8px;
            border: 1px solid #e9ecef; min-height: 60px;
        }
        .signal.digital-true { border-left: 4px solid #28a745; background: linear-gradient(90deg, rgba(40,167,69,0.05) 0%, white 10%); }
        .signal.digital-false { border-left: 4px solid #dc3545; background: linear-gradient(90deg, rgba(220,53,69,0.05) 0%, white 10%); }
        .signal.analog { border-left: 4px solid #007bff; background: linear-gradient(90deg, rgba(0,123,255,0.05) 0%, white 10%); }
        .signal-name { font-weight: 600; color: #2c3e50; flex: 1; margin-right: 15px; }
        .signal-value {
            font-family: monospace; background: #f8f9fa; color: #495057;
            padding: 6px 12px; border-radius: 6px; border: 1px solid #dee2e6;
            font-weight: 600; min-width: 80px; text-align: center;
        }
        .signal.digital-true .signal-value { background: #d4edda; color: #155724; border-color: #c3e6cb; }
        .signal.digital-false .signal-value { background: #f8d7da; color: #721c24; border-color: #f5c6cb; }
        .refresh-info { text-align: center; margin-top: 20px; color: #6c757d; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 Simple PLC Bridge Dashboard</h1>
            <p>No SSE, No Complexity - Just Simple HTTP Polling</p>
        </div>

        <div class="info">
            <h3>📊 System Info</h3>
            <div>Signals: <span id="signal-count">0</span></div>
            <div>Last Update: <span id="last-update">Never</span></div>
            <div>Status: <span id="status">Loading...</span></div>
        </div>

        <div class="info">
            <h3>⚡ Live Signals</h3>
            <div class="signals-grid" id="signals"></div>
        </div>
        
        <div class="refresh-info">
            Dashboard refreshes every 3 seconds via simple HTTP polling
        </div>
    </div>

    <script>
        function updateSignals() {
            fetch('/signals')
                .then(response => response.json())
                .then(data => {
                    const container = document.getElementById('signals');
                    const signals = data.signals || [];
                    
                    container.innerHTML = signals.map(signal => {
                        const isDigital = signal.signal_name && (
                            signal.signal_name.includes('PICK') || 
                            signal.signal_name.includes('PLC_') || 
                            typeof signal.value === 'boolean'
                        );
                        const cssClass = isDigital ? (signal.value ? 'digital-true' : 'digital-false') : 'analog';
                        const displayValue = isDigital ? (signal.value ? 'TRUE' : 'FALSE') : signal.value;
                        
                        return `
                            <div class="signal ${cssClass}">
                                <div class="signal-name">${signal.signal_name || signal.name}</div>
                                <div class="signal-value">${displayValue}</div>
                            </div>
                        `;
                    }).join('');
                    
                    document.getElementById('signal-count').textContent = signals.length;
                    document.getElementById('last-update').textContent = new Date().toLocaleTimeString();
                    document.getElementById('status').textContent = 'Connected';
                })
                .catch(error => {
                    document.getElementById('status').textContent = 'Connection Error';
                    console.error('Error:', error);
                });
        }
        
        // Update immediately and then every 3 seconds
        updateSignals();
        setInterval(updateSignals, 3000);
    </script>
</body>
</html>'''
        return html


def main():
    """Entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Simple PLC Bridge")
    parser.add_argument("--frappe-url", default="http://backend:8000", help="Frappe server URL")
    parser.add_argument("--poll-interval", type=float, default=3.0, help="Polling interval in seconds")
    
    args = parser.parse_args()
    
    bridge = SimplePLCBridge(
        frappe_url=args.frappe_url,
        poll_interval=args.poll_interval
    )
    
    # Signal handlers
    import signal
    def signal_handler(sig, frame):
        print("Shutting down...")
        bridge.stop()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        if bridge.start():
            print("Simple PLC Bridge running on http://localhost:7654")
            # Keep main thread alive
            while True:
                time.sleep(1)
        else:
            print("Failed to start bridge")
            sys.exit(1)
    
    except KeyboardInterrupt:
        bridge.stop()
    except Exception as e:
        print(f"Unhandled exception: {e}")
        bridge.stop()
        sys.exit(1)

if __name__ == "__main__":
    main()