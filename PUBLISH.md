# MovieSee — Google Play Market Chiqarish Yo'riqnomasi

## 1. KEYSTORE YARATISH (bir marta)

```bash
keytool -genkey -v \
  -keystore android/moviesee-release.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias moviesee
```

Keyin `android/key.properties.template` ni `android/key.properties` ga nusxalab,
haqiqiy parollar bilan to'ldiring:

```
storePassword=<keystore parolingiz>
keyPassword=<kalit parolingiz>
keyAlias=moviesee
storeFile=../moviesee-release.jks
```

> ⚠️  `key.properties` va `moviesee-release.jks` ni hech qachon git ga push qilmang!
>     `.gitignore` da allaqachon yozilgan.

---

## 2. RELEASE AAB BUILD QILISH

```bash
flutter build appbundle --release
```

Tayyor fayl: `build/app/outputs/bundle/release/app-release.aab`

---

## 3. PLAY CONSOLE DA QILISH KERAK BO'LGAN ISHLAR

### A. Yangi Ilova Yaratish
- play.google.com/console → "Ilova yaratish"
- Dastur turi: **Ilova** | Bepul
- Til: O'zbek / Rus / Ingliz

### B. Store Listing (Do'kon sahifasi)
- [ ] Ilova nomi: **MovieSee**
- [ ] Qisqa tavsif (80 belgi): "Do'stlar bilan birgalikda video tomosha qiling — ovozli aloqa bilan"
- [ ] To'liq tavsif (4000 belgi)
- [ ] Ekran tasvirlari: kamida **2 ta** (telefon uchun 1080x1920 yoki 1080x2340)
- [ ] Feature Graphic: 1024×500 px
- [ ] Ilova ikoni: 512×512 px (yuqori sifatli)

### C. Content Rating (Yosh cheklovi)
- Play Console → Content Rating → IARC savolnomasini to'ldiring
- MovieSee uchun: Foydalanuvchi tomonidan yaratilgan kontent (chat), ovozli aloqa bor

### D. Data Safety (Ma'lumotlar xavfsizligi)
To'ldirish kerak bo'lgan ma'lumotlar:

| Ma'lumot turi | Yig'iladimi? | Maqsad |
|---|---|---|
| Email manzil | Ha | Akkaunt |
| Foydalanuvchi nomi | Ha | Akkaunt |
| Ovozli ma'lumot | Yo'q (real vaqt, saqlanmaydi) | — |
| Qurilma identifikatori (FCM) | Ha | Push bildirishnoma |

- **Maxfiylik siyosati URL**: ilova ichida `/privacy-policy` sahifasi bor,
  lekin Play Console uchun tashqi URL kerak.
  Masalan: GitHub Pages yoki Render static page orqali joylashtiring.

### E. Permissions Declaration (Ruxsatlar izohi)
Play Console → Ilova mazmuni → "Nozik ruxsatlar":
- **RECORD_AUDIO**: "Xonada boshqa foydalanuvchilar bilan ovozli gaplashish uchun"
- **CAMERA**: "Video muloqot uchun (ixtiyoriy)"

---

## 4. AAB YUKLASH VA TEST

1. Play Console → Test → **Internal Testing** → Yangi chiqarish
2. `app-release.aab` ni yuklang
3. Testerlar sifatida o'zingizni qo'shing (email)
4. Qurilmaga Play Store dan yuklab test qiling
5. Hammasi ishlasa → **Production** ga ko'taring

---

## 5. PRODUCTION CHIQARISH

- Play Console → Production → Yangi chiqarish → AAB yuklash
- Chiqarish izohi (Release notes) yozing:
  ```
  v1.0.0 — Birinchi versiya
  • Birgalikda video tomosha qilish
  • Ovozli aloqa (WebRTC)
  • Chat
  • Xona taklifi (push bildirishnoma)
  ```
- "Ko'rib chiqishga yuborish" → Google 1-3 kun ichida tekshiradi

---

## 6. MUHIM ESLATMALAR

- `key.properties` → `.gitignore` da bo'lishi SHART
- `moviesee-release.jks` ni xavfsiz joyda saqlang (yo'qolsa yangi versiya chiqara olmaysiz)
- `versionCode` har yangilashda oshirilishi kerak (pubspec.yaml: `version: 1.0.0+1` → `+2`)
- targetSdk=36 (Android 15) — 2025-yil avgust 31 gacha majburiy ✅

---

## 7. PLAY STORE SIYOSATI TEKSHIRUVI

- [ ] Maxfiylik siyosati URL kiritildi
- [ ] Data Safety to'ldirildi
- [ ] Content Rating to'ldirildi
- [ ] Ruxsatlar izohlandi
- [ ] Ilova faqat HTTPS/WSS ishlatadi ✅
- [ ] Mikrofon/kamera ruxsatlari dialog bilan so'raladi ✅
- [ ] targetSdk = 36 ✅
