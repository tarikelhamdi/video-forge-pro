# تثبيت FFmpeg على Windows

## الطريقة 1: التثبيت السريع (مستحسن)

### باستخدام Chocolatey:
```powershell
# في PowerShell كمسؤول:
choco install ffmpeg
```

### باستخدام Scoop:
```powershell
# في PowerShell:
scoop install ffmpeg
```

---

## الطريقة 2: التثبيت اليدوي

### 1. تحميل FFmpeg:
- افتح الموقع: https://www.gyan.dev/ffmpeg/builds/
- حمّل ملف: **ffmpeg-release-full.7z**

### 2. استخراج الملفات:
- استخرج الملف إلى مجلد مثل: `C:\ffmpeg`
- ستجد ملفات `ffmpeg.exe` و `ffprobe.exe` في: `C:\ffmpeg\bin`

### 3. إضافة FFmpeg إلى PATH:

#### الطريقة السهلة:
1. اضغط `Win + R` واكتب: `sysdm.cpl`
2. اذهب إلى تبويب **Advanced**
3. اضغط **Environment Variables**
4. تحت **System variables**, ابحث عن **Path** واضغط **Edit**
5. اضغط **New** وأضف: `C:\ffmpeg\bin`
6. اضغط **OK** على جميع النوافذ

#### عبر PowerShell (كمسؤول):
```powershell
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\ffmpeg\bin",
    "Machine"
)
```

### 4. التحقق من التثبيت:
```powershell
# أعد فتح PowerShell وجرّب:
ffmpeg -version
```

إذا ظهرت معلومات FFmpeg، فالتثبيت ناجح! ✅

---

## حل المشاكل الشائعة:

### المشكلة: "ffmpeg is not recognized"
**الحل:**
- تأكد أنك أضفت المسار الصحيح إلى PATH
- أغلق وأعد فتح PowerShell/CMD
- أعد تشغيل الكمبيوتر إذا لزم الأمر

### المشكلة: "access denied"
**الحل:**
- شغّل PowerShell/CMD كمسؤول (Run as Administrator)

---

## بعد تثبيت FFmpeg:

### 1. بناء مكتبة C++:
```powershell
cd cpp
.\build.bat
```

### 2. تشغيل التطبيق:
```powershell
flutter run -d windows
```

---

## اختبار FFmpeg في التطبيق:

1. افتح التطبيق
2. اذهب إلى شاشة **Video Editor**
3. استورد ملف فيديو
4. اضغط **Start Processing**

إذا كل شيء يعمل، ستبدأ المعالجة! 🎬
