# BACKLOG — فیچرها، فقط عنوان

<!--
  قانون: اینجا فقط عنوان + یک خط. جزئیات هر فیچر فقط وقتی نوبتش شد،
  توی ریپوی همون سرویس با /brief نوشته می‌شه (سقف ۳۰ خط).
  جزئیاتِ از قبل نوشته = جزئیاتِ باطل‌شده.
-->

## Milestone 0 — برش نازک سرتاسری ⭐

هدف: اثبات اتصال identity ↔ core ↔ notification با یک فلوی واقعی.
تا این سبز نشده، هیچ فیچر دیگه‌ای شروع نمی‌شه.

- [ ] identity: ثبت‌نام با موبایل → صدور OTP → فراخوانی notification
- [ ] notification: endpoint ارسال + driver ‏`log` (بدون provider واقعی)
- [ ] identity: تأیید OTP → صدور JWT (RS256) + refresh + `/.well-known/jwks.json`
- [ ] core: صفحه ثبت‌نام/ورود که با identity کار می‌کنه (session روی Redis)
- [ ] core: پنل کاربر → نمایش پروفایل خودش (`users.view_own`)
- [ ] core: پنل ادمین → لیست کاربرها از identity (‏`users.view_any`)
- [ ] core: پنل سوپرادمین → همون + مدیریت ادمین‌ها (`admins.manage`)
- [ ] تست قرارداد identity در برابر `contracts/identity.openapi.yaml`
- [ ] docker-compose ریپوی dev: هر سه سرویس + MariaDB + Redis + Mailpit با یک دستور

**Done یعنی:** یه نفر غریبه بتونه ثبت‌نام کنه، OTP رو (از لاگ) بزنه، وارد
پنل کاربر بشه؛ و ادمین لیستش رو ببینه. `php artisan test` هر سه ریپو سبز.

## Milestone 1 — پرداخت + تخفیف

- [ ] payment: ساخت پرداخت + driver درگاه [sandbox] + webhook idempotent
- [ ] discount: CRUD کد + endpoint اعتبارسنجی + ثبت مصرف بعد از موفقیت
- [ ] core: فلوی checkout (اعمال کد → پرداخت → نتیجه)
- [ ] notification: driver واقعی sms [+ email SMTP] + قالب‌ها
- [ ] webhook پرداخت: idempotent، منبع حقیقتِ وضعیت تراکنش

## Milestone 2 — مدیا و تکمیل پنل‌ها

- [ ] media: آپلود + لینک امضاشده + اتصال به core
- [ ] پنل‌ها: [گزارش‌ها، تنظیمات، … — با دامنه محصولت پر کن]

## بعداً / شاید

- [ ] [هر ایده‌ای که وسوسه شدی الان بسازی، بنداز اینجا]
