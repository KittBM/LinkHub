# LinkHub

## Product Overview

LinkHub คือระบบที่ช่วยให้ Tablet สามารถทำหน้าที่เป็นศูนย์กลางในการควบคุมและติดตามสถานะของโทรศัพท์ Android หลายเครื่อง โดยเชื่อมต่อผ่าน Wi-Fi หรือ Bluetooth

### Key Features

* Notification Mirroring
* Call Management
* SMS Management
* Device Monitoring
* Clipboard Synchronization
* Screen Mirroring
* Remote Control
* File Transfer
* Audio Relay
* Multi-device Management

---

# Product Vision

เปลี่ยน Tablet ให้เป็น Control Center สำหรับโทรศัพท์ Android หลายเครื่อง

ผู้ใช้สามารถ:

* ดู Notification จากทุกเครื่อง
* รับและจัดการสายโทรศัพท์
* ส่งข้อความ
* ตรวจสอบสถานะอุปกรณ์
* ควบคุมโทรศัพท์จากระยะไกล

โดยไม่จำเป็นต้องหยิบโทรศัพท์ขึ้นมาใช้งาน

---

# Version 1 (MVP)

## Objective

สร้างระบบ Companion Device ที่ให้ Tablet สามารถติดตามและควบคุมฟังก์ชันพื้นฐานของ Phone ได้

---

## Functional Requirements

### FR-001 Device Pairing

#### Description

ผู้ใช้สามารถจับคู่ Tablet และ Phone ได้

#### Acceptance Criteria

* Scan อุปกรณ์ใน Network เดียวกัน
* Pair ด้วย QR Code
* Pair ด้วย PIN Code
* รองรับ 1 Tablet ต่อหลาย Phone

---

### FR-002 Device Management

#### Description

แสดงรายการอุปกรณ์ที่เชื่อมต่อ

#### Acceptance Criteria

แสดงข้อมูล:

* Device Name
* Battery Level
* Connection Status
* Last Seen Timestamp

---

### FR-003 Notification Mirroring

#### Description

แสดง Notification จาก Phone บน Tablet

#### Acceptance Criteria

รองรับ Notification จาก:

* LINE
* WhatsApp
* Messenger
* Gmail
* SMS
* Application อื่นที่ Android อนุญาต

ข้อมูลที่แสดง:

* Application Name
* Sender / Title
* Message
* Timestamp

---

### FR-004 Notification Actions

#### Description

จัดการ Notification จาก Tablet

#### Acceptance Criteria

รองรับ:

* Reply
* Mark as Read
* Dismiss

---

### FR-005 Incoming Call Mirroring

#### Description

แสดงสายเรียกเข้าบน Tablet

#### Acceptance Criteria

แสดงข้อมูล:

* Caller Name
* Phone Number
* Contact Avatar

รองรับ:

* Accept
* Reject

---

### FR-006 Call Control

#### Description

ควบคุมสายโทรศัพท์ผ่าน Tablet

#### Acceptance Criteria

รองรับ:

* Accept Call
* Reject Call
* End Call
* Mute Call

---

### FR-007 SMS Management

#### Description

จัดการ SMS ผ่าน Tablet

#### Acceptance Criteria

รองรับ:

* Read SMS
* Send SMS
* Search SMS

---

### FR-008 Device Monitoring

#### Description

แสดงสถานะของ Phone

#### Acceptance Criteria

แสดง:

* Battery Percentage
* Charging Status
* Wi-Fi Status
* Mobile Signal
* Storage Usage

---

### FR-009 Clipboard Synchronization

#### Description

Sync Clipboard ระหว่าง Device

#### Acceptance Criteria

* Copy จาก Phone → Paste บน Tablet
* Copy จาก Tablet → Paste บน Phone

---

## Non-Functional Requirements

### NFR-001 Performance

* Notification Delay < 1 Second

### NFR-002 Battery Consumption

* Agent App ใช้พลังงานไม่เกิน 5% ต่อวัน

### NFR-003 Security

* AES-256-GCM Encryption
* Device Authentication
* Pairing Token Verification

---

## Version 1 Architecture

```text
Tablet App
      │
  WebSocket
      │
Phone Agent
```

### Communication

Primary

```text
Wi-Fi (Local Network)
```

Fallback

```text
Bluetooth LE
```

---

# Version 2 (Advanced)

## Objective

เพิ่มความสามารถในการควบคุม Phone แบบเต็มรูปแบบจาก Tablet

---

## Additional Functional Requirements

### FR-101 Screen Mirroring

#### Description

แสดงหน้าจอ Phone แบบ Real-time

#### Acceptance Criteria

* Latency < 300ms
* Resolution 720p
* 15-30 FPS

---

### FR-102 Remote Touch Control

#### Description

ควบคุมหน้าจอ Phone ผ่าน Tablet

#### Acceptance Criteria

รองรับ:

* Tap
* Double Tap
* Swipe
* Long Press
* Scroll

---

### FR-103 Remote Navigation

#### Description

ควบคุม Navigation ของ Android

#### Acceptance Criteria

รองรับ:

* Home
* Back
* Recent Apps

---

### FR-104 App Launcher

#### Description

เปิดและสลับแอปจาก Tablet

#### Acceptance Criteria

รองรับ:

* Open App
* Close App
* Switch App

---

### FR-105 File Transfer

#### Description

ส่งไฟล์ระหว่าง Device

#### Acceptance Criteria

รองรับ:

* Image
* Video
* PDF
* APK
* Documents

---

### FR-106 Audio Relay

#### Description

ส่งเสียงจาก Phone มายัง Tablet

#### Acceptance Criteria

รองรับ:

* Call Audio
* Media Audio
* Notification Audio

---

### FR-107 Full Call Experience

#### Description

คุยโทรศัพท์ผ่าน Tablet

#### Acceptance Criteria

รองรับ:

* Tablet Speaker
* Tablet Microphone
* Bluetooth Headset

---

### FR-108 Camera Proxy

#### Description

ควบคุมกล้อง Phone ผ่าน Tablet

#### Acceptance Criteria

รองรับ:

* Live Preview
* Capture Photo
* Record Video

---

### FR-109 Multi Device Control

#### Description

ควบคุมหลาย Phone พร้อมกัน

#### Acceptance Criteria

รองรับ:

* Device Switching
* Concurrent Monitoring
* Device Grouping

---

### FR-110 Automation Rules

#### Description

สร้าง Automation ระหว่าง Device

#### Examples

##### Example 1

```text
When Incoming Call from Boss
→ Show Priority Notification
```

##### Example 2

```text
When Battery < 20%
→ Send Alert to Tablet
```

---

## Non-Functional Requirements

### NFR-101 Remote Control Latency

* < 100ms

### NFR-102 Video Streaming

* 720p @ 30 FPS

### NFR-103 Scalability

รองรับ:

* 1 Tablet
* สูงสุด 10 Phones

### NFR-104 Reliability

Auto Reconnect ภายใน:

```text
5 Seconds
```

---

# Technical Specification

## Frontend

### Tablet Application

```text
Flutter
Riverpod
go_router
```

---

### Phone Agent

```text
Flutter
+
Kotlin
```

---

## Android Native Components

```text
NotificationListenerService
AccessibilityService
ForegroundService
MediaProjection
TelecomManager
BluetoothManager
```

---

## Communication Layer

### Version 1

```text
WebSocket
```

### Version 2

```text
WebRTC
```

---

## Local Database

เลือกใช้:

```text
Hive
```

---

## Security

```text
AES-256-GCM
```

```text
Device Pairing Token
```

```text
Public / Private Key Authentication
```

---

# Roadmap

## Phase 1

Duration: 4-6 Weeks

### Deliverables

* Device Pairing
* Device Management
* Notification Mirroring
* SMS Management

---

## Phase 2

Duration: 2-4 Weeks

### Deliverables

* Incoming Call Mirroring
* Call Control
* Clipboard Sync

---

## Release V1

---

## Phase 3

Duration: 6-8 Weeks

### Deliverables

* Screen Mirroring
* File Transfer
* Audio Relay

---

## Phase 4

Duration: 6-8 Weeks

### Deliverables

* Remote Control
* Automation Engine
* Multi Device Support

---

## Release V2
