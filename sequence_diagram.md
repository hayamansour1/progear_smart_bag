# ProGear Smart Bag - Sequence Diagrams

## 1. App Initialization and Home Dashboard Flow

```mermaid
sequenceDiagram
    participant Main as main()
    participant Supabase as Supabase Client
    participant ActivityStore as ActivitySeenStore
    participant Providers as MultiProvider
    participant BTController as BluetoothController
    participant BatteryCtrl as BatteryController
    participant WeightCtrl as WeightController
    participant BatteryBridge as BatteryBridge
    participant WeightBridge as WeightBridge
    participant AuthGate as AuthGate
    participant HomePage as HomeDashboardPage

    Main->>Supabase: Initialize(url, anonKey)
    Main->>ActivityStore: init()
    Main->>Providers: Create MultiProvider
    Providers->>BTController: Create (BlueServiceImpl)
    Providers->>BatteryCtrl: Create (BagParser, Repository)
    Providers->>WeightCtrl: Create (BagParser)
    BatteryCtrl->>Supabase: boot() - getStatus(controllerID)
    WeightCtrl->>Supabase: boot() - get expectedWeight
    Main->>BatteryBridge: attachContext(context)
    Main->>WeightBridge: attachContext(context)
    Providers->>AuthGate: Build App
    AuthGate->>Supabase: Check auth session
    alt User authenticated
        AuthGate->>HomePage: Navigate to HomeDashboardPage
        HomePage->>HomePage: build() - Render widgets
    else User not authenticated
        AuthGate->>AuthGate: Show LoginPage
    end
```

## 2. Bluetooth Connection and Data Streaming Flow

```mermaid
sequenceDiagram
    participant UI as HomeDashboardPage
    participant BTController as BluetoothController
    participant BlueService as BlueServiceImpl
    participant Device as BluetoothDevice
    participant BatteryBridge as BatteryBridge
    participant BatteryCtrl as BatteryController
    participant WeightBridge as WeightBridge
    participant WeightCtrl as WeightController
    participant Parser as BagParser
    participant Supabase as Supabase DB

    UI->>BTController: startScan()
    BTController->>BlueService: startScan()
    BlueService-->>BTController: Stream scan results
    BTController-->>UI: notifyListeners() - Update devices list
    
    UI->>BTController: connectDevice(device)
    BTController->>BlueService: disconnect(other devices)
    BTController->>BlueService: connect(device)
    BlueService->>Device: Establish connection
    Device-->>BTController: Connection state: connected
    BTController-->>UI: notifyListeners() - Update connectedDevice
    
    BTController->>BatteryBridge: bind(characteristic)
    BatteryBridge->>BatteryCtrl: bindToCharacteristic(ch)
    BatteryCtrl->>Parser: bind(characteristic)
    Parser->>Device: Subscribe to notifications
    Device-->>Parser: BLE data stream
    
    BTController->>WeightBridge: bind(characteristic)
    WeightBridge->>WeightCtrl: bindToCharacteristic(ch)
    WeightCtrl->>Parser: bind(characteristic)
    Parser->>Device: Subscribe to notifications
    Device-->>Parser: BLE data stream
    
    Note over Parser: Receives: {"bat":72,"chg":1} or {"w":6234}
    Parser-->>BatteryCtrl: Stream line: "{"bat":72,"chg":1}"
    BatteryCtrl->>BatteryCtrl: _onLine() - Parse JSON/text
    BatteryCtrl->>BatteryCtrl: applyReading(percent: 72, charging: true)
    BatteryCtrl-->>UI: notifyListeners() - Update battery state
    BatteryCtrl->>Supabase: _maybeUploadToDB() - setStatus()
    
    alt Battery <= 20% (from >= 21%)
        BatteryCtrl->>Supabase: rpc('insert_notification', battery_low)
        BatteryCtrl->>ActivityStore: bumpUnread(controllerID)
    end
    
    Parser-->>WeightCtrl: Stream line: "{"w":6234}"
    WeightCtrl->>WeightCtrl: _onLine() - Parse JSON/text
    WeightCtrl->>WeightCtrl: _applyReading(currentG: 6234)
    WeightCtrl->>WeightCtrl: Calculate deltaG = currentG - expectedG
    WeightCtrl-->>UI: notifyListeners() - Update weight state
    
    alt |deltaG| >= 200g threshold
        WeightCtrl->>Supabase: rpc('insert_notification', weight_delta)
        WeightCtrl->>ActivityStore: bumpUnread(controllerID)
    end
```

## 3. Reset Expected Weight Flow

```mermaid
sequenceDiagram
    participant User as User
    participant HomePage as HomeDashboardPage
    participant ResetSheet as ResetWeightSheet
    participant Supabase as Supabase DB
    participant WeightCtrl as WeightController
    participant ActivityStore as ActivitySeenStore
    participant Toast as ProGearToast

    User->>HomePage: Tap "Reset Expected Weight" button
    HomePage->>HomePage: _openResetSheet()
    HomePage->>ResetSheet: showModalBottomSheet()
    ResetSheet->>ResetSheet: initState()
    ResetSheet->>Supabase: Load snapshot (currentWeight, inserted_at)
    Supabase-->>ResetSheet: Return current weight data
    ResetSheet-->>User: Display reset sheet with current weight hint
    
    User->>ResetSheet: Tap "Done" button
    ResetSheet->>ResetSheet: _confirmReset()
    
    ResetSheet->>Supabase: rpc('reset_expected_to_current', p_controller)
    Supabase->>Supabase: Update expectedWeight = currentWeight
    Supabase-->>ResetSheet: Success
    
    ResetSheet->>Supabase: rpc('insert_notification', weight_reset)
    Supabase-->>ResetSheet: Notification created
    
    ResetSheet->>WeightCtrl: applyExpectedFromReset(expectedG)
    WeightCtrl->>WeightCtrl: Update _expectedG, _deltaG
    WeightCtrl-->>HomePage: notifyListeners() - UI updates
    
    ResetSheet->>ActivityStore: bumpUnread(controllerID)
    ResetSheet->>Toast: show('Expected weight updated')
    ResetSheet->>ResetSheet: Navigator.pop(context, true)
    ResetSheet-->>HomePage: Sheet dismissed
```

## 4. Home Header Activity Navigation Flow

```mermaid
sequenceDiagram
    participant HomeHeader as HomeHeader Widget
    participant BTController as BluetoothController
    participant ActivityStore as ActivitySeenStore
    participant Router as GoRouter
    participant ActivityPage as ActivityPage

    Note over HomeHeader: On initState
    HomeHeader->>HomeHeader: _init()
    HomeHeader->>HomeHeader: _resolveControllerID()
    Note over HomeHeader: TEMP: returns 'ctrl_14be0569'
    HomeHeader->>ActivityStore: hasUnread(controllerID)
    ActivityStore-->>HomeHeader: Return unread status
    HomeHeader->>HomeHeader: setState(_unread = true/false)
    HomeHeader-->>User: Display header with unread dot if needed
    
    User->>HomeHeader: Tap Activity button
    HomeHeader->>HomeHeader: setState(_unread = false)
    HomeHeader->>Router: push('/activity?cid=controllerID')
    Router->>ActivityPage: Navigate to ActivityPage
    ActivityPage->>ActivityPage: Load notifications
    ActivityPage->>ActivityStore: Mark as read
    ActivityPage-->>User: Display activity notifications
    
    User->>ActivityPage: Navigate back
    ActivityPage-->>HomeHeader: Return to HomeDashboardPage
    HomeHeader->>ActivityStore: hasUnread(controllerID) - Re-check
    ActivityStore-->>HomeHeader: Updated unread status
    HomeHeader->>HomeHeader: setState(_unread = updated)
```

## 5. Battery Low Notification Flow

```mermaid
sequenceDiagram
    participant BLE as BLE Device
    participant Parser as BagParser
    participant BatteryCtrl as BatteryController
    participant Supabase as Supabase DB
    participant ActivityStore as ActivitySeenStore
    participant HomeHeader as HomeHeader
    participant User as User

    BLE-->>Parser: Stream: {"bat":25,"chg":0}
    Parser-->>BatteryCtrl: Line: "{"bat":25,"chg":0}"
    BatteryCtrl->>BatteryCtrl: _onLine() - Parse
    BatteryCtrl->>BatteryCtrl: applyReading(percent: 25)
    Note over BatteryCtrl: Previous: 21%, Current: 25%<br/>No threshold crossed
    
    BLE-->>Parser: Stream: {"bat":20,"chg":0}
    Parser-->>BatteryCtrl: Line: "{"bat":20,"chg":0}"
    BatteryCtrl->>BatteryCtrl: _onLine() - Parse
    BatteryCtrl->>BatteryCtrl: applyReading(percent: 20)
    Note over BatteryCtrl: Previous: 25% >= 21%<br/>Current: 20% <= 20%<br/>Threshold crossed!
    
    BatteryCtrl->>Supabase: rpc('insert_notification')<br/>kind: 'battery_low'
    Supabase-->>BatteryCtrl: Notification created
    BatteryCtrl->>ActivityStore: bumpUnread(controllerID)
    BatteryCtrl-->>HomeHeader: notifyListeners() - Update UI
    HomeHeader->>ActivityStore: hasUnread(controllerID)
    ActivityStore-->>HomeHeader: true
    HomeHeader-->>User: Display blue unread dot
    
    BatteryCtrl->>Supabase: _maybeUploadToDB() - setStatus()
    Supabase-->>BatteryCtrl: Battery status saved
```

## 6. Weight Delta Alert Flow

```mermaid
sequenceDiagram
    participant BLE as BLE Device
    participant Parser as BagParser
    participant WeightCtrl as WeightController
    participant Supabase as Supabase DB
    participant ActivityStore as ActivitySeenStore
    participant HomePage as HomeDashboardPage
    participant User as User

    Note over WeightCtrl: expectedG = 8000g, threshold = ±200g
    
    BLE-->>Parser: Stream: {"w":8150}
    Parser-->>WeightCtrl: Line: "{"w":8150}"
    WeightCtrl->>WeightCtrl: _onLine() - Parse weight
    WeightCtrl->>WeightCtrl: _applyReading(currentG: 8150)
    WeightCtrl->>WeightCtrl: deltaG = 8150 - 8000 = 150g
    Note over WeightCtrl: |150| < 200, no alert
    WeightCtrl-->>HomePage: notifyListeners() - Update UI
    
    BLE-->>Parser: Stream: {"w":8250}
    Parser-->>WeightCtrl: Line: "{"w":8250}"
    WeightCtrl->>WeightCtrl: _onLine() - Parse weight
    WeightCtrl->>WeightCtrl: _applyReading(currentG: 8250)
    WeightCtrl->>WeightCtrl: deltaG = 8250 - 8000 = 250g
    Note over WeightCtrl: 250 >= 200 (threshold)<br/>Check cooldown & direction
    
    WeightCtrl->>Supabase: rpc('insert_notification')<br/>kind: 'weight_delta',<br/>severity: 'warn'
    Supabase-->>WeightCtrl: Notification created
    WeightCtrl->>ActivityStore: bumpUnread(controllerID)
    WeightCtrl-->>HomePage: notifyListeners() - Update UI
    HomePage-->>User: Display updated weight with warning indicator
```

