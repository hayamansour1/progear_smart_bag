# ProGear Smart Bag  
Smart IoT-Enabled Bag for Battery Monitoring, Weight Tracking, and Real-Time BLE Communication using ESP32


---

## Overview  
ProGear Smart Bag is an integrated hardware–software system designed to enhance user safety and convenience through real-time monitoring. The system combines embedded sensors, BLE communication, and a mobile application to provide weight tracking, battery level monitoring, and automated calibration features.

The solution is implemented using ESP32 hardware, HX711 load cells, a custom BLE protocol, and a Flutter-based mobile application connected to Supabase.

---

## Features  
- Real-time weight tracking using load cells and HX711 modules  
- Battery percentage monitoring through ADC voltage measurement  
- Live Bluetooth Low Energy (BLE) communication  
- Custom BLE message protocol (JSON-based)  
- Automated and manual calibration functions  
- Secure Supabase backend for user data and device status  
- Modular and scalable software architecture  
- Background services for app-level state management  

---

## System Architecture  

### Hardware Layer  
- ESP32-WROOM microcontroller  
- HX711 amplifier + dual load cells  
- Battery monitoring circuit (ADC + voltage divider)  
- Power management and wiring infrastructure  

### Firmware Layer  
- BLE UART service  
- JSON-based command protocol  
- Weight measurement and smoothing  
- Battery calculation logic  
- NVS storage for calibration values  

### Mobile Application Layer (Flutter)  
- Controllers (Battery, Weight, BLE)  
- Bridges for hardware-to-UI interaction  
- Supabase integration (device binding, expected weight, logs)  
- Real-time dashboards  
- Authentication and device assignment  

### Cloud Backend (Supabase)  
- Auth  
- Device records  
- Weight and battery logs  
- Policies and security rules  

---

## Hardware Components  
- ESP32-WROOM microcontroller  
- HX711 module  
- Two load cells (A/B)  
- 3.7V lithium battery  
- Voltage divider circuit  
- Wires, connectors, and PCB/breadboard assembly  

---

## Firmware Overview  
The firmware is written in C++ using the Arduino framework and handles:

- BLE RX/TX  
- Weight sampling through HX711  
- Calibration commands  
- Battery percentage calculation  
- NVS storage for saved values  

### BLE Service  
- UART Service UUID  
- RX characteristic for receiving commands  
- TX characteristic for sending responses  

### Protocol Format  
Commands are sent as lines ending with `\n`.

#### Example Commands  
PING  
RESET_WEIGHT  
GET_WEIGHT  
GET_BATTERY  
SET_EXPECTED:4500

#### Example Responses  
STATUS_UPDATE {"state":"ble_connected"}  
WEIGHT_DATA {"g": 1234.0}  
BATTERY {"percent": 87, "chg": 0}  

---

## Mobile App Overview  
The Flutter application uses:  
- Provider state management  
- MVC-inspired architecture  
- Service layer for BLE  
- Controllers for business logic  
- Bridges for UI updates  

### Main Modules  
- BluetoothController  
- WeightController  
- BatteryController  
- AuthGate  
- Dashboard UI  

---

## Setup Steps  
This project is delivered as a compressed folder containing all required files.

### Step 1: Extract Files  
Unzip the project folder.

### Step 2: Firmware Setup  
1. Open the firmware folder in Arduino IDE or VS Code.  
2. Install required libraries (ESP32 BLE, HX711, ArduinoJSON).  
3. Connect ESP32 via USB.  
4. Flash the firmware.  

### Step 3: Hardware Assembly  
1. Connect load cells to HX711.  
2. Connect HX711 to ESP32 pins.  
3. Connect the battery through a voltage divider.  
4. Power the ESP32 and check BLE advertising.  

### Step 4: Mobile App  
1. Open the Flutter project.  
2. Run `flutter pub get`.  
3. Add Supabase URL and anon key in environment files.  
4. Run the app on a physical device using `flutter run`.  

### Step 5: Device Pairing  
1. Scan for nearby devices in the app.  
2. Connect to the ProGear Smart Bag.  
3. The system will determine whether the device is new or previously initialized.  

---

## Project Structure  

### Mobile App  
lib/  
  core/  
  features/  
    home/  
    bag/  
    weight/  
    bluetooth/  
  services/  
  main.dart  

### Firmware  
firmware/  
progear.ino

---

## Testing  
- Unit tests on weight, battery, and BLE controllers  
- BLE connectivity and stability tests  
- Calibration validation  
- Battery measurement validation  
- End-to-end testing with full hardware assembly  

---

## Team Members  

### Haya Mansour Bin Samih  
Responsible for system protocol design, overall system architecture, full mobile application development, BLE data processing, and firmware–application integration workflow.

### Hessa Almaarik  
Responsible for implementing the Bluetooth Low Energy (BLE) scanning feature and establishing device connection within the mobile application.

### Sara Alrahma  
Responsible for hardware development including sensor wiring, circuit assembly, and integration of load cells with the ESP32 microcontroller.

---

## Acknowledgements  
This project was completed under the supervision of **T. Shatha Alkhaldi** from the Information Technology Department at Imam Mohammad Ibn Saud Islamic University.

---

## License  
Internal academic project. Not licensed for commercial use.
