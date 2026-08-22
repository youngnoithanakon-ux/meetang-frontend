# มีตังค์ (MeeTang) - Frontend App 📱💰

แอปพลิเคชัน "มีตังค์" (MeeTang) เป็นแอปจัดการการเงินส่วนบุคคล พัฒนาด้วย **Flutter** รองรับการใช้งานแบบ Cross-platform ทั้งบน Android และ iOS พร้อม UI ที่สวยงาม ทันสมัย และใช้งานง่าย

## 🚀 ฟีเจอร์หลัก (Features)
- 🔐 **ระบบความปลอดภัย:** ระบบ Login / Register พร้อมฟีเจอร์การสแกนนิ้ว/สแกนใบหน้า (Biometrics) ก่อนเข้าแอป
- 💼 **กระเป๋าเงินลากวางได้:** หน้า Dashboard แบบ Interactive สามารถแตะค้างที่กระเป๋าแล้ว "ลากไปวาง" ใส่กระเป๋าอื่นเพื่อโอนเงินได้อย่างรวดเร็ว!
- 🎯 **เป้าหมายการออม (Savings Goal):** ตั้งเป้าหมายการออมเงิน พร้อมหลอด Progress Bar สีส้ม/เขียว ดูความคืบหน้าได้ทันที
- 💸 **จัดการรายรับ-รายจ่าย:** บันทึกรายการเข้า-ออก พร้อมแนบรูปสลิป/ใบเสร็จได้
- 🔁 **ระบบหักเงินประจำ (Recurring):** ตั้งเวลาหักเงิน/โอนเงินล่วงหน้า เช่น จ่ายค่า Netflix ทุกวันที่ 1 ระบบจะตัดให้อัตโนมัติเมื่อเปิดแอป
- 📊 **กราฟและงบประมาณ:** สรุปรายจ่ายแต่ละเดือนผ่านกราฟวงกลม (Pie Chart) พร้อมตั้งงบประมาณ (Budget Limit) รายหมวดหมู่
- 🎨 **UI/UX ทันสมัย:** ดีไซน์สะอาดตา ใช้งานง่าย รองรับการเลื่อน ปัด ลาก (Gestures) อย่างสมบูรณ์แบบ

## 🛠️ Tech Stack
- **Framework:** Flutter (Dart)
- **State Management / HTTP:** `http` package สำหรับต่อ API
- **Local Storage:** `shared_preferences` สำหรับเก็บ Token และลำดับกระเป๋าเงิน
- **Biometrics:** `local_auth` สำหรับระบบสแกนลายนิ้วมือ/ใบหน้า
- **Charts:** `fl_chart` สำหรับแสดงผลกราฟสถิติ
- **Image Handling:** `image_picker` สำหรับอัปโหลดสลิป

## 📥 การติดตั้ง (Installation)

1. **Clone โปรเจกต์**
   ```bash
   git clone https://github.com/youngnoithanakon-ux/meetang-frontend.git
   cd meetang-frontend
   ```

2. **ติดตั้ง Packages**
   ```bash
   flutter pub get
   ```

3. **ตั้งค่า Backend API**
   เข้าไปที่ไฟล์ `lib/services/api_service.dart` และแก้ไข IP ให้ตรงกับ Server (หรือ IPv4 ของเครื่องคอมพิวเตอร์คุณหากรัน Backend บน Localhost)
   ```dart
   static const String serverIp = '49.1.1.47:8000'; // เปลี่ยนเป็น IP ของเซิร์ฟเวอร์คุณ
   static const String baseUrl = 'http://$serverIp/api';
   ```

4. **รันแอปพลิเคชัน**
   ```bash
   flutter run
   ```

## 📂 โครงสร้างโปรเจกต์ (Folder Structure)
- `lib/screens/` - หน้า UI ต่างๆ เช่น Dashboard, History, Budgets, Recurring
- `lib/services/` - ไฟล์จัดการการเชื่อมต่อกับ Backend (ApiService)
- `lib/widgets/` - UI Components ที่ใช้ซ้ำได้

## 📱 หมายเหตุสำหรับการบิลด์ (Build Notes)
- **Android:** หากพบปัญหา License หรือการตั้งค่า Gradle ให้ตรวจสอบการติดตั้ง Android SDK command-line tools
- **iOS:** จำเป็นต้องใช้ macOS และติดตั้ง Xcode สำหรับการคอมไพล์เป็นไฟล์ iOS (.ipa)
