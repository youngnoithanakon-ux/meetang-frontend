# มีตังค์ (MeeTang) - Frontend App 📱💰

แอปพลิเคชัน "มีตังค์" (MeeTang) เป็นแอปจัดการการเงินส่วนบุคคล พัฒนาด้วย **Flutter** รองรับการใช้งานแบบ Cross-platform ทั้งบน Android และ iOS พร้อม UI ที่สวยงาม ทันสมัย และใช้งานง่าย

## 🚀 ฟีเจอร์หลัก (Features)
- 🔐 **ระบบความปลอดภัย (Security):** ระบบ Login / Register พร้อมสแกนนิ้ว/สแกนใบหน้า (Biometrics) ก่อนเข้าแอป
- 🌙 **โหมดกลางคืน (Dark Mode):** ถนอมสายตาด้วย Dark Mode ที่สามารถเปิดปิดได้จากหน้าจัดการบัญชี
- 💼 **จัดการกระเป๋าเงินล้ำสมัย (Interactive Dashboard):**
  - แสดงภาพรวมยอดเงินและรายรับรายจ่ายแบบ Dashboard
  - **ลากสลับตำแหน่ง:** กดที่ไอคอน `≡` แล้วลากเพื่อจัดลำดับกระเป๋าตามใจชอบ
  - **ลากโอนเงิน (Drag to Transfer):** กดค้าง (Long press) ที่ตัวกระเป๋า แล้วลากไปทับกระเป๋าใบอื่นเพื่อทำการโอนเงินทันที!
- 🎯 **เป้าหมายการออม (Savings Goal):** ตั้งเป้าหมายการออมเงิน พร้อมหลอด Progress Bar ดูความคืบหน้าได้ทันที
- 💸 **บันทึกรายรับ-รายจ่าย:** จดบันทึกพร้อมแนบรูปสลิป/ใบเสร็จได้ (ดึงรูปผ่าน API ทะลุ Cloudflare ได้ 100%)
- 🪄 **ระบบปรับสมดุลอัตโนมัติ (Auto-Adjustment):** หากเข้าไปแก้ตัวเลขยอดเงินในกระเป๋า ระบบจะคำนวณส่วนต่างและสร้างรายการรายรับ/รายจ่ายให้อัตโนมัติ เพื่อให้ประวัติตรงกับยอดเงิน
- 🔁 **ระบบหักเงินประจำ (Recurring):** ตั้งเวลาหักเงิน/โอนเงินล่วงหน้า เช่น จ่ายค่า Netflix ทุกวันที่ 1 ระบบจะตัดให้อัตโนมัติเมื่อเปิดแอป
- 📊 **กราฟและหมวดหมู่:** สรุปรายจ่ายแต่ละเดือนผ่านกราฟ พร้อมมินิกราฟ 7 วันล่าสุดบนหน้า Dashboard

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
   เข้าไปที่ไฟล์ `lib/services/api_service.dart` และแก้ไข URL ให้ตรงกับ Server หรือโดเมนของคุณ
   ```dart
   static const String serverIp = 'meetang.heyroll.site'; 
   static const String baseUrl = 'https://$serverIp/api';
   ```

4. **รันแอปพลิเคชัน / Build APK**
   ```bash
   flutter run
   // หรือ
   flutter build apk --release
   ```

## 📂 โครงสร้างโปรเจกต์ (Folder Structure)
- `lib/screens/` - หน้า UI ต่างๆ เช่น Dashboard, History, Budgets, Recurring, Profile
- `lib/services/` - ไฟล์จัดการการเชื่อมต่อกับ Backend (ApiService)
- `lib/widgets/` - UI Components ที่ใช้ซ้ำได้

## 📱 หมายเหตุสำหรับการบิลด์ (Build Notes)
- **Android Permissions:** ใน AndroidManifest.xml ได้เพิ่มสิทธิ์ `INTERNET` และ `USE_BIOMETRIC` เรียบร้อยแล้ว เพื่อให้รองรับการสแกนนิ้วและการดึงข้อมูลผ่าน API ในเวอร์ชัน Release
