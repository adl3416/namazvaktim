# Do Not Disturb (Rahatsız Etme) İzni Kurulumu

## Genel Bakış

Namaz bildirimlerinin telefon "Do Not Disturb" (Rahatsız Etme / Sessiz) modunda çalışabilmesi için Android cihazlarda özel bir izin gereklidir. Bu doküman, uygulama yüklendikten sonra ne yapılması gerektiğini açıklar.

## Ne Değiştirildi?

### 1. **Dependency Eklendi** 📦
```yaml
permission_handler: ^11.3.0
```
Bu paket, Android izinlerini kontrol etmek ve talep etmek için kullanılır.

### 2. **Android Manifest Güncellendi** 📋
```xml
<uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY"/>
```
Bu izin, Do Not Disturb modunu kontrol etmeyi sağlar.

### 3. **NotificationService Güncellendi** 🔔
- `_checkAndRequestDoNotDisturbPermission()` metodu eklendi
- Uygulama başladığında otomatik olarak izin kontrol edilir
- Eğer izin yoksa, kullanıcıya gösterilen bir diyalog açılır

### 4. **Navigasyon Anahtarı Eklendi** 🔑
`main.dart`'a `navigatorKey` eklendi:
```dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
```
Bu, notification service'den diyalog gösterebilmek için gereklidir.

### 5. **Çoklu Dil Desteği** 🌍
Localization dosyasına aşağıdaki çeviriler eklendi:
- **Türkçe (tr)**: Do Not Disturb izni açıklaması
- **İngilizce (en)**: Do Not Disturb izni açıklaması
- **Arapça (ar)**: Do Not Disturb izni açıklaması

## Kurulum Adımları (Kullanıcı için)

### Android'de Do Not Disturb İzni Açmak

**Seçenek 1: Uygulama İçinde (Otomatik)**
1. Uygulamayı ilk kez açtığınızda, "Do Not Disturb" izni isteyen bir diyalog gösterilir
2. "Ayarlara Git" butonuna tıklayın
3. Sistem ayarları açılacaktır (aşağıdaki adımları takip edin)

**Seçenek 2: Manuel Ayarlanması**

#### Android 12+
1. **Ayarlar** > **Uygulamalar** > **Namaz Vakitleri** 
2. **İzinler** bölümüne gidin
3. **Bildirimleri Yönet** veya **Bildirim İlkeleri** bölümüne bakın
4. **Rahatsız Etme Erişimi** ✓ (Enable)

#### Android 11 ve Öncesi
1. **Ayarlar** > **Uygulamalar ve Bildirimler** > **Uygulama İzinleri**
2. **Bildirim İlkeleri** veya **Do Not Disturb Access** bölümüne gidin
3. **Namaz Vakitleri** uygulamasını etkinleştirin

#### Doğrudan Ayarlar Yolu
1. **Ayarlar** > **Uygulamalar** (veya **Uygulama Yöneticisi**)
2. Üç nokta menüsünden **Özel Uygulamalar Erişimi** seçin
3. **Bildirim İlkeleri Erişimi** bölümüne gidin
4. **Namaz Vakitleri** ✓ (Enable)

## Neden Bu İzin Gerekli?

- 🔇 **Sessiz Modu Aşma**: Do Not Disturb modundayken bile bildirimler çalışır
- 🔔 **Ezan Sesi**: Adhan (ezan) sesinin çalınabilmesini sağlar
- 📳 **Titreşim**: Cihaz titreyebilir
- 🎵 **Ses**: Bildirim sesi duyulur

## Sistem Ayarlarındaki Yerleri

```
Android Ayarları
├── Uygulamalar (Apps)
│   └── Namaz Vakitleri
│       └── İzinler (Permissions)
│           └── Bildirim İlkeleri Erişimi (Notification Policy Access)
│
├── Ses ve Titreşim
│   └── Rahatsız Etme (Do Not Disturb)
│       └── Muaf Uygulamalar (Exempted Apps)
│           └── Namaz Vakitleri ✓
│
└── Bildirimler
    └── Namaz Vakitleri
        └── Bildirim Türü: Önemli (Importance: High)
```

## Sorun Giderme

### Diyalog Görüntülenmiyor
- Uygulama yeniden başlatın
- Telefonunuzu yeniden başlatın

### İzin Hala Verilmemiş
- Ayarlar > Uygulamalar > Namaz Vakitleri > İzinler'e manuel olarak gidin
- Bildirim İlkeleri Erişimini etkinleştirin

### Bildirimler Hala Sessiz Modunda Çalışmıyor
- **Rahatsız Etme Ayarları**'ndan Namaz Vakitleri'ni muaf uygulamalar listesine ekleyin
- Bildirim Kanalı ayarlarını kontrol edin (Önemli olmalı)

## Teknik Detaylar

### API Seviyesi
- Minimum SDK: Android 5.0+ (API 21)
- Hedef SDK: Android 15+ (API 35)

### İzin Türü
- Runtime Permission (Çalışma Zamanında İstenir)
- Manifest'te bildirilir
- İlk açılışta istenir

### İşlem Akışı
```
Uygulama Başlat
    ↓
NotificationService.initialize()
    ↓
_checkAndRequestDoNotDisturbPermission()
    ↓
Permission.notificationPolicy.status kontrol et
    ↓
    ├─ İzin Verildi → ✓ (Devam et)
    ├─ İzin Reddedildi → İzin iste
    │   ├─ Kabul Edildi → ✓ (Devam et)
    │   └─ Reddedildi → Diyalog göster
    └─ İzin Sorulacak → İzin iste
```

## Kod Referansı

### notification_service.dart
```dart
// Do Not Disturb izni kontrol ve talep
static Future<void> _checkAndRequestDoNotDisturbPermission() async {
  final status = await Permission.notificationPolicy.status;
  if (status.isDenied) {
    final result = await Permission.notificationPolicy.request();
    if (result.isPermanentlyDenied) {
      _showDoNotDisturbSettingsDialog();
    }
  }
}

// Kullanıcıyı ayarlara yönlendiren diyalog
static void _showDoNotDisturbSettingsDialog() {
  final context = getContext();
  if (context != null && context.mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.translate('dnd_permission_title', 'tr')),
        content: Text(AppLocalizations.translate('dnd_permission_message', 'tr')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.translate('later', 'tr')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text(AppLocalizations.translate('go_to_settings', 'tr')),
          ),
        ],
      ),
    );
  }
}
```

## Özet

✅ **Otomatik İzin Talebi**: Uygulama ilk açılışında izin istenir
✅ **Kullanıcı Dostu**: Açıklayıcı diyalog gösterilir
✅ **Çoklu Dil**: Türkçe, İngilizce, Arapça desteği
✅ **Ayarları Açma**: Doğrudan sistem ayarlarına yönlendirme
✅ **Fallback**: Otomatik istem başarısız olursa manuel kurulum rehberi sağlanır

---

**Son Güncelleme**: 4 Şubat 2026
**Durum**: Hazır ve Test Edilmiş ✓
