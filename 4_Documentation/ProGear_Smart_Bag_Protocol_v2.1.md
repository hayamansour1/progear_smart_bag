# ProGear Smart Bag Communication Protocol

**Version:** 2.1  
**Last Updated:** November 2025  
**Maintainer:** Haya Al-Samih  
*This version (v2.1) supersedes v2.0 (October 2025).*

---

## 1. Overview
This document defines the communication protocol between the **ProGear Smart Bag firmware (ESP32)** and the **mobile application (Flutter)** over Bluetooth Low Energy (BLE).  
All messages are exchanged as **UTF-8 encoded text**, terminated by a newline character (`\n`).  

This project uses a custom BLE protocol instead of standard BLE services to support structured JSON messages, session-based weight logic, and real-time synchronization tailored to the smart bag use case.

The protocol is **stateless** and designed for low-latency operation — each command/response is self-contained and human-readable for debugging purposes.


---

## 2. Message Format

Each packet follows the format:

```
TAG:JSON\n
```

| Component | Description |
|------------|-------------|
| **TAG** | Uppercase identifier for message type (e.g., `STATUS_UPDATE`, `WEIGHT_DATA`, `BATTERY`). |
| **JSON** | Object containing structured data relevant to the tag. |
| **\n** | Line terminator required for parsing by the Flutter BLE stream reader. |

Example:
```
WEIGHT_DATA:{"g":18250.4}\n
```

---

## 3. Core Tags

### 3.1 STATUS_UPDATE
Indicates hardware or system status.

| Key | Type | Example | Description |
|------|------|----------|-------------|
| `state` | string | `"scale_ready"` | Human‑readable state indicator. |
| `expected_weight_g` | float (optional) | `8200` | Sent only when expected weight is updated. |

**Possible States**
- `ble_advertising` — BLE started advertising.  
- `scale_ready` — Load cells initialized successfully.  
- `scale_not_ready` — HX711 not responding or unstable.  
- `tare_done` — Scale reset completed.  
- `baseline_reset` — Baseline recalibrated.  
- `pong` — Response to `PING` command.  

---

### 3.2 WEIGHT_DATA
Periodic stream of live readings from both load cells.

| Key | Type | Example | Description |
|------|------|----------|-------------|
| `g` | float | `18250.4` | Current total weight in grams. |

Sent every **~500 ms** when active.  
Transmission is throttled — only sent when weight changes by ≥ 1 g.

---

### 3.3 SESSION_FINAL
Triggered once per “stable session” — when the bag remains quiet for ≥ 2.5 s within ±20 g.

| Key | Type | Example |
|------|------|----------|
| `g` | float | `18200.0` | Final stable reading. |

---

### 3.4 ERROR
Reports hardware or measurement issues.  
Repeated errors are rate‑limited (cooldown ≈ 2 s).

| Key | Type | Example | Description |
|------|------|----------|-------------|
| `msg` | string | `"over_capacity"` | Exceeded safe weight range. |

**Common Messages**
- `over_capacity` — Weight exceeds `MAX_G` (10 kg).  
- `scale_not_ready` — HX711 not connected or misread.  

---

### 3.5 BATTERY
Reports battery status of the device.

| Key | Type | Example | Description |
|------|------|----------|-------------|
| `percent` | int | `72` | Battery level (0–100 %). |
| `chg` | int | `1` | Charging state (`1` = charging, `0` = not charging). |

**Anti‑Spam Logic**
- Sent **only if** level changes by ≥ 2 %.  
- Minimum interval between sends = 30 s.  
- Always sent on startup or when `GET_BAT` is received.

---

## 4. BLE Commands (App → Firmware)

| Command | Example | Description |
|----------|----------|-------------|
| `PING` | `PING\n` | Requests connection check → firmware replies with `STATUS_UPDATE:{"state":"pong"}`. |
| `RESET_WEIGHT` | `RESET_WEIGHT\n` | Performs tare calibration on both load cells, resets baseline. |
| `SET_EXPECTED_WEIGHT:<g>` | `SET_EXPECTED_WEIGHT:8200\n` | Stores target expected weight in NVS memory. |
| `GET_EXPECTED_WEIGHT` | `GET_EXPECTED_WEIGHT\n` | Replies with `STATUS_UPDATE:{"expected_weight_g":<value>}`. |
| `GET_BAT` | `GET_BAT\n` | Triggers immediate battery response. |
| `GET_WEIGHT` | `GET_WEIGHT\n` | Returns one‑time reading `WEIGHT_DATA:{...}` for diagnostics. |

---

## 5. Persistence Layer (NVS)

| Key | Type | Description |
|------|------|-------------|
| `exp_g` | float | Last expected weight value set by `SET_EXPECTED_WEIGHT`. |

Values persist across device restarts.

---

## 6. Timing & Cooldowns

| Parameter | Default | Purpose |
|------------|----------|----------|
| `SEND_MS` | 500 ms | Interval for weight updates. |
| `QUIET_MS` | 2500 ms | Time window for stable session detection. |
| `QUIET_EPS` | ±20 g | Threshold for “quiet” weight stability. |
| `ERR_COOLDOWN_MS` | 2000 ms | Minimum delay between repeated error messages. |
| `BAT_PUSH_MS` | 30000 ms | Minimum delay between battery updates. |

---

## 7. Example Session

```
STATUS_UPDATE:{"state":"scale_ready"}
STATUS_UPDATE:{"state":"tare_done"}
WEIGHT_DATA:{"g":18234.1}
WEIGHT_DATA:{"g":18249.9}
SESSION_FINAL:{"g":18250.0}
BATTERY:{"percent":71,"chg":0}
```

---

## 8. Changelog

| Version | Date | Summary |
|----------|------|----------|
| 2.1 | Nov 2025 | Added anti‑spam battery logic, cooldowns, NVS persistence, and refined stability detection. |
| 2.0 | Oct 2025 | Initial stable protocol release for dual load‑cell integration. |
| 1.x | – | Experimental iterations during prototype stage. |
