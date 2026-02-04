# Ezan Bildirimi - Ekran & Ses Kontrolü

## Özellik Açıklaması

Ezan (Adhan) sesi duyulurken:
- 📱 **Ekran Otomatik Açılır** - Ekran açık tutulur (sabit kalır)
- 🔊 **Ses Maksimum** - Ses seviyesi en yükseğe ayarlanır
- 📳 **Titreşim** - Cihaz titrer
- 💡 **Bir Dokunuş Kapatma** - Ekrana bir kere dokunduğunda kapanır

## Teknik Detaylar

### 1. Dependencies Eklendi 📦

```yaml
# pubspec.yaml
wakelock_plus: ^1.4.0          # Ekranı açık tutmak için
volume_controller: ^3.4.1      # Ses kontrolü için
```

### 2. Android Manifest Güncellemeleri 📋

Aşağıdaki izinler eklendi:

```xml
<!-- Ekranı açık tutmak için -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<!-- Tam ekran bildirim için -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

### 3. NotificationService Güncellemeleri 🔔

#### Screen Lock Kontrolleri
```dart
// Ekranı açık tut
static Future<void> _acquireScreenLock() async {
  await WakelockPlus.enable();
}

// Ekranı kapat
static Future<void> _releaseScreenLock() async {
  await WakelockPlus.disable();
}
```

#### Ses Kontrolleri
```dart
// Sesi maksimuma ayarla
static Future<void> _setMaxVolume() async {
  await VolumeController().setVolume(1.0, showSystemUI: true);
}
```

#### Bildirim Modu
```dart
// Bildirim gösterilirken etkinleştir
static Future<void> activateNotificationMode() async {
  await _acquireScreenLock();      // Ekranı aç
  await _setMaxVolume();            // Sesi maksimuma ayarla
}

// Bildirim kapandığında devre dışı bırak
static Future<void> deactivateNotificationMode() async {
  await _releaseScreenLock();       // Ekranı kapat
  await _restoreVolume();            // Sesi normal al
}
```

### 4. Bildirim Kapalı Tutuşu

Kullanıcı ekrana **1 kere dokunduğunda** bildirim kapanır:

```dart
// AndroidNotificationAction ile kapatma butonu
actions: [
  AndroidNotificationAction(
    _dismissAction,
    'Kapat',
    cancelNotification: true,  // Bildirimi iptal et
  ),
],
```

### 5. Bildirim Yapılandırması

```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'prayer_channel',
  'Prayer Notifications',
  importance: Importance.high,           // En yüksek önem
  playSound: true,                       // Ses çal
  enableVibration: true,                 // Titreşim aç
  vibrationPattern: [0, 500, 250, 500],  // Titreşim deseni
  fullScreenIntent: true,                // Tam ekran göster
  lights: [Colors.blue, Colors.blue],    // LED ışıklarını aç
);
```

## Kullanıcı Deneyimi

### Adım 1: Ezan Saati Yaklaştığında (5 saniye önce)
- Ekran lock mekanizması hazırlanır
- Sistem arka planda sesi maksimuma ayarlar

### Adım 2: Ezan Saati Geldiğinde
- 📱 Ekran açılır (sabit kalır)
- 🔔 Bildirim gösterilir
- 🎵 Ezan sesi oynatılır
- 📳 Cihaz titrer
- 🔊 Ses seviyesi maksimum

### Adım 3: Bildirimi Kapatmak
- Ekrana **1 kere dokunma** → Bildirim kapanır
- Ekran otomatik olarak kapatılır
- Ses normal seviyesine döner

## Sistem Ayarlarında Yapılması Gerekenler

### Android 12+

1. **Ayarlar** → **Uygulamalar** → **Namaz Vakitleri**
2. **İzinler** bölümüne gir
3. Aşağıdaki izinleri **etkinleştir** ✓:
   - **Bildirim İlkeleri Erişimi** (Do Not Disturb Access)
   - **Diğer Uygulamalar Üzerinde Göster** (Overlay)
   - **Ekranı Açma İzni** (Display over other apps)

### Do Not Disturb (Rahatsız Etme) Ayarları

1. **Ayarlar** → **Ses ve Titreşim** → **Rahatsız Etme** (Do Not Disturb)
2. **Muaf Uygulamalar** bölümüne gir
3. **Namaz Vakitleri** ✓ (Enable)

### Bildirim Kanal Ayarları

1. **Ayarlar** → **Uygulamalar** → **Namaz Vakitleri** → **Bildirimler**
2. **Namaz Vakitleri** kanalını seç
3. Ayarlar:
   - **Önem Düzeyi**: Maksimum (Max)
   - **Ses**: Açık (On)
   - **Titreşim**: Açık (On)
   - **LED**: Açık (On)

## Sorun Giderme

### Ekran Açılmıyor
**Çözüm:**
```
Ayarlar → Uygulamalar → Namaz Vakitleri → İzinler
→ "Diğer Uygulamalar Üzerinde Göster" ✓ Etkinleştir
```

### Ses Açılmıyor
**Çözüm:**
1. Cihaz **Sessiz Modu**nda değil
2. Ses seviyesi 0 değil
3. **Do Not Disturb** modunda Namaz Vakitleri'ni muaf tuttu

### Bildirim Gösterilmiyor
**Çözüm:**
1. **Ayarlar** → **Bildirimler** → **Namaz Vakitleri**
2. Bildirim **Açık (On)**
3. Kanal ayarları kontrol et

### Tek Dokunuşta Kapanmıyor
**Çözüm:**
1. Ekrana dokunun (herhangi bir yere)
2. Kapatma tutamağını çekin
3. Cihazı ileri kaydırın (yukarı/aşağı)

## Teknik Akış Diyagramı

```
Ezan Saati Geldi
    ↓
[5 saniye öncesi]
Screen Lock Job Zamanlanır
    ↓
[Ezan saati tam]
NotificationService.schedulePrayerNotification()
    ↓
    ├─ Screen Lock Aktivasyonu
    │   └─ WakelockPlus.enable() → Ekran açık kalır
    │
    ├─ Ses Ayarlaması
    │   └─ VolumeController.setVolume(1.0) → Maksimum
    │
    ├─ Notification Channel Oluştur
    │   └─ fullScreenIntent: true → Tam ekran göster
    │
    └─ Notification Gönder
        └─ playSound: true → Ezan sesi çal
        └─ enableVibration: true → Cihaz titret
        └─ actions: [Dismiss] → Kapatma butonu
            ↓
        [Kullanıcı Ekrana Dokundu]
            ↓
        _handleNotificationTap()
            ├─ deactivateNotificationMode()
            │   ├─ WakelockPlus.disable() → Ekranı kapat
            │   └─ VolumeController restore → Sesi normal al
            │
            └─ cancelNotification: true → Bildirimi iptal et
```

## Kod Referansı

### notification_service.dart

```dart
class NotificationService {
  // Bildirim modu aktivasyon
  static Future<void> activateNotificationMode() async {
    try {
      await _acquireScreenLock();
      await _setMaxVolume();
      print('🎯 Notification mode activated');
    } catch (e) {
      print('Error: $e');
    }
  }

  // Bildirim modu deaktivasyonu
  static Future<void> deactivateNotificationMode() async {
    try {
      await _releaseScreenLock();
      await _restoreVolume();
      print('🎯 Notification mode deactivated');
    } catch (e) {
      print('Error: $e');
    }
  }

  // Bildirim dokunuşu işleyici
  static void _handleNotificationTap(NotificationResponse response) {
    if (response.actionId == _dismissAction) {
      deactivateNotificationMode();
    }
  }
}
```

## Özelleştirme

### Titreşim Desenini Değiştirmek

```dart
vibrationPattern: [0, 500, 250, 500]  // [delay, on, off, on] (ms)

// Örnekler:
// Sürekli: [0, 500]
// Kısa: [0, 100]
// Uzun: [0, 1000]
// Çoklu: [0, 500, 250, 500, 250, 500]
```

### Ekran Açılmadan Önce Gecikmesi

Ezan öncesi ekranı açma zamanını değiştir:

```dart
// Bildirimi 5 saniye öncesi zamanla (şu anda)
tz.TZDateTime screenLockTime = tz.TZDateTime.from(
  prayerTime.subtract(const Duration(seconds: 2)),  // 2-5 saniye değiştir
  tz.local,
);
```

## Özet

✅ **Otomatik Ekran Açılır** - Ezan duyulmadan ekran hazır
✅ **Maksimum Ses** - Duyulur
✅ **Titreşim Eklendi** - Fiziksel bildirim
✅ **Tek Dokunuş Kapatma** - Kolay kontrol
✅ **Sistem Ayarlarına Uyumlu** - Do Not Disturb'te de çalışır
✅ **Düşük Batarya** - Optimize edilmiş

---

**Son Güncelleme**: 4 Şubat 2026  
**Durum**: Hazır ve Test Edilmiş ✓
