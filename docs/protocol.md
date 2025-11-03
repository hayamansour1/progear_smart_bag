# ProGear Smart Bag Communication Protocol

**Version:** 1.0  
**Last Updated:** November 2025  
**Maintainer:** Haya Al-Samih  

---

## 1. Architecture Overview

The ProGear Smart Bag system follows a **BLE + Cloud hybrid model**, where the ESP32 controller handles hardware-level weight sensing and battery monitoring, while the Flutter application manages cloud storage and analytics through Supabase.

**Flow Summary:**
- Flutter App ↔ ESP32 via BLE commands and JSON messages.  
- Flutter App ↔ Supabase via RPC functions (data synchronization).  

**Simplified Flow:**
Flutter App → (BLE) → ESP32 Controller → (Data) → Flutter App → (RPC) → Supabase

---

## 2. Overview

This document defines the official communication protocol between the **ESP32 Controller** and the **Flutter Application**.  
It specifies all message formats, commands, and response structures used to exchange data over BLE.  
All numeric values use **grams (g)** as the unit of weight.

---

## 3. Units

All weight values are represented in **grams (g)**.

---

## 4. Commands (App → ESP32)

| Command | Example | Description |
|----------|----------|-------------|
| `PING` | `PING` | Used to check connectivity. ESP32 should respond with `PONG`. |
| `SET_EXPECTED_WEIGHT:<value>` | `SET_EXPECTED_WEIGHT:20000` | Updates the expected (target) weight in grams. |
| `RESET_WEIGHT` | `RESET_WEIGHT` | Performs a hardware-level tare operation (resets the scale). |
| `GET_EXPECTED_WEIGHT` | `GET_EXPECTED_WEIGHT` | Requests the current expected weight stored in NVS memory. |
 
**Notes:**
- Commands are **plain text**, terminated by a newline character `\n`.  
- Commands are **case-insensitive**, but uppercase is recommended for clarity.  
 
---

## 5. Messages (ESP32 → App)

| Message | Example | Description |
|----------|----------|-------------|
| `WEIGHT_DATA:{"g":18250.4}` | Continuous real-time weight readings in grams. |
| `SESSION_FINAL:{"g":18200.0}` | Final stable reading after movement stops. |
| `STATUS_UPDATE:{"state":"scale_ready"}` | Reports device or sensor status updates. |
| `ERROR:{"msg":"over_capacity"}` | Error or alert message sent from ESP32. |

**Notes:**
- Messages are formatted as **JSON** for flexibility and readability.  
- Each message ends with a newline (`\n`).  
- The Flutter app parses these messages using the `BagParser` service.  
 
---

## 6. Synchronization Flow
 
1. The Flutter app connects to the ESP32 device via BLE.  
2. The app retrieves the latest `expectedWeight` from Supabase.  
3. The app sends `SET_EXPECTED_WEIGHT:<value>` to ESP32.  
4. The ESP32 acknowledges the update with a `STATUS_UPDATE` message.  
5. During an active session, the ESP32 streams continuous `WEIGHT_DATA` messages.  
6. The app stores these readings in Supabase using the `insert_weight_reading()` RPC.  
7. When the user performs a reset, the app calls `reset_expected_to_current()` and re-sends the new expected weight to the ESP32.

---

## 7. Example Communication Session

[APP] PING  
[ESP32] PONG  

[APP] SET_EXPECTED_WEIGHT:20000  
[ESP32] STATUS_UPDATE:{"expected_weight_g":20000}

[ESP32] WEIGHT_DATA:{"g":20120.3}  
[ESP32] WEIGHT_DATA:{"g":20110.8}  
[ESP32] SESSION_FINAL:{"g":20100.0}
 
---

## 8. Error Handling and Recovery
 
If ESP32 sends an error message such as: 

ERROR:{"msg":"over_capacity"}

Then:
- The app displays a user-friendly message or toast notification.  
- The current session continues unless the error type requires disconnection.  
- If BLE connection is lost, the app automatically retries or notifies the user.  
- All critical errors are logged locally for diagnostics.  
 
---

## 9. Integration Notes

This protocol integrates directly with the following Flutter modules:

- **WeightController:** Parses live BLE weight readings and syncs with Supabase.  
- **BatteryController:** Parses battery data and stores updates.  
- **WeightBridge / BatteryBridge:** Connect BLE characteristics to the respective controllers.  
- **Supabase RPC Functions:**
  - `insert_weight_reading`
  - `reset_expected_to_current`
  - `set_battery_status`

**Data Formats:**
- App → ESP32: plain text commands.  
- ESP32 → App: JSON messages.   

---

## 10. Future Enhancements

| Area | Description |
|-------|-------------|
| Push Notifications | Add automatic alerts via Supabase Edge Functions / FCM. |
| Data Compression | Support binary streaming for faster BLE data transfer. |
| Encryption | Implement AES-128 for secure data exchange. |
| Multi-Sensor Support | Extend JSON format to handle multiple load sensors. |

---

**© 2025 ProGear Smart Bag Team**  
_All rights reserved._
