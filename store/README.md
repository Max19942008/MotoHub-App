# Google Play materiallari — MOTOPRESTO (Android)

| Fayl | Play Console'da qayerga |
| --- | --- |
| `build/app/outputs/bundle/release/app-release.aab` | Testing → Closed testing → Create release |
| `listing-uz.md`, `listing-en.md`, `listing-ru.md` | Grow → Store presence → Main store listing (tarjimalar: "Manage translations") |
| `play_icon_512.png` | App icon (512×512) |
| `feature_graphic_1024x500.png` | Feature graphic (1024×500) |
| `screenshots/*.png` | Phone screenshots (1080×2160, kamida 2 ta, 8 tagacha) |

- **Package name:** `online.motopresto.app` (keyin o'zgartirib bo'lmaydi)
- **Upload key:** `C:\dev\keys\motohub-upload.jks` (alias `upload`). Google Drive'ga zaxira qiling (D: emas!). Play App Signing'ni yoqing (standart).
- **Privacy policy URL:** https://motopresto.online/privacy
- **Account deletion URL:** https://motopresto.online/account/delete

## Create app
- App name: **MOTOPRESTO** · Default language: **English (United States) – en-US** (yoki o'zbek) · **App** (game emas) · **Free**
- Declarations: Developer Program Policies ✓, US export laws ✓

## Store settings
- **Category:** Auto & Vehicles
- **Tags:** Marketplace, Motorcycles (taklif qilingan ro'yxatdan)
- **Contact email:** shaxsiy emailingiz · **Website:** https://motopresto.online · **Phone:** ixtiyoriy

## App content javoblari

**Privacy policy:** https://motopresto.online/privacy

**App access:** *All or some functionality is restricted* → Add instructions:
- Name: `Reviewer account`
- Username / Password: `C:\dev\keys\play-review-account.txt` dagi login va parol
- Instructions: "Open the app → My page (bottom bar) → Log in. Browsing listings, the AI assistant and the help centre work without login; favourites, profile, writing articles and account deletion need login."

**Ads:** No, my app does not contain ads.

**Content rating (IARC):** Category → *All Other App Types*. Zo'ravonlik, qo'rqinchli, jinsiy, so'kinish, giyohvand, qimor — hammasiga **No**. Users can interact / exchange content — **Yes** (e'lonlar, maqolalar, profil). Shares user's current location — **No**. Digital purchases — **No**. Unrestricted internet / web browser — **No**.

**Target audience:** **18+** (savdo e'lonlari va telefon raqamlar ko'rinadi; bolalar siyosati talablaridan qochish uchun). "Appeal to children" — No.

**News app:** No · **COVID-19:** No · **Data safety:** pastda · **Government app:** No · **Financial features:** My app doesn't provide any financial features · **Health:** No · **Advertising ID:** No (ilova ishlatmaydi).

## Data safety
- Collect or share any required user data types? **Yes**
- All data encrypted in transit? **Yes** (HTTPS)
- Way for users to request deletion? **Yes** — ilova ichida (My page → Profil → Hisobni o'chirish) va https://motopresto.online/account/delete
- Account creation: **Username and password** · Delete account URL: https://motopresto.online/account/delete

Yig'iladigan ma'lumotlar (hammasi **Collected**, **Shared: No**, **Not ephemeral**):

| Turi | Majburiymi | Maqsad |
| --- | --- | --- |
| Personal info → **Name** (nik, ixtiyoriy ism) | Required | App functionality, Account management |
| Personal info → **Phone number** | Required | App functionality, Account management |
| Personal info → **Address** (profildagi manzil) | Optional | App functionality |
| Personal info → **User IDs** | Required | App functionality, Account management |
| Photos and videos → **Photos** (profil va e'lon rasmlari) | Optional | App functionality |
| App activity → **App interactions** (sevimlilar, ko'rilganlar, obunalar) | Optional | App functionality |
| App activity → **Other user-generated content** (e'lonlar, maqolalar, AI'ga savollar) | Optional | App functionality |

"Shared: No" — Google Gemini, Cloudinary, MongoDB Atlas sizning nomingizdan ishlov beradigan service provider'lar; Play qoidasi bo'yicha bu "sharing" emas. Boshqa foydalanuvchilar ilova ichida ko'rishi ham sharing emas.

Yig'ilmaydi: joylashuv, kontaktlar, email, moliyaviy, sog'liq, qurilma ID, analitika, crash log.

## Release
1. **Closed testing** → track yarating → Testers: email ro'yxati (kamida **12 kishi**), opt-in havolasini ularga yuboring.
2. Create release → `app-release.aab` yuklang → Release name `1.0.0 (1)` → Release notes: `listing-*.md` oxirida.
3. Countries: Uzbekistan, South Korea (yoki hammasi).
4. 12 tester **14 kun** ketma-ket o'rnatib turgandan keyin → Production access so'rash.
