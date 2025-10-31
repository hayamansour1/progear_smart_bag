# ProGear Smart Bag Communication Protocol

## Overview
Defines how the ESP32 controller and Flutter application communicate.

### Unit:
All weight values are in **grams (g)**.

---

## Commands from App → ESP32
| Command | Example | Description |
|----------|----------|-------------|
| `PING` | `PING` | Checks connectivity. |
| `SET_EXPECTED_WEIGHT:<value>` | `SET_EXPECTED_WEIGHT:20000` | Sets expected weight in grams. |
| `RESET_WEIGHT` | `RESET_WEIGHT` | Re-tare the scale (hardware-level). |
| `GET_EXPECTED_WEIGHT` | `GET_EXPECTED_WEIGHT` | Request expected weight stored in NVS. |

---

## Messages from ESP32 → App
| Message | Example | Meaning |
|----------|----------|----------|
| `WEIGHT_DATA:{"g":18250.4}` | Realtime weight in grams. |
| `SESSION_FINAL:{"g":18200.0}` | Final stable weight after motion. |
| `STATUS_UPDATE:{"state":"scale_ready"}` | Device status update. |
| `ERROR:{"msg":"over_capacity"}` | Error or alert message. |

---

## Synchronization Flow
1. App connects to ESP32.  
2. App reads expectedWeight from Supabase.  
3. App sends `SET_EXPECTED_WEIGHT:<value>` to ESP32.  
4. Device confirms (optional).  
5. During active session, ESP32 sends continuous `WEIGHT_DATA` to App.  
6. App inserts readings to Supabase via `insert_weight_reading`.  
7. On Reset, app runs `reset_expected_to_current()` and resends new expected weight.

---

## Example Scenario
```text
[APP] SET_EXPECTED_WEIGHT:20000  
[ESP32] STATUS_UPDATE:{"expected_weight_g":20000}
[ESP32] WEIGHT_DATA:{"g":20120.3}
[ESP32] SESSION_FINAL:{"g":20100.0}
