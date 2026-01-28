# Ezan Ses Dosyaları Kurulumu

## Ses Dosyalarını Yerleştirme

`assets/sounds/` klasörüne aşağıdaki ezan ses dosyalarını yerleştirin:

### Gereken Ses Dosyaları:

1. **sabah_ezan.mp3** - Sabah namazı ezanı
2. **ogle_ezan.mp3** - Öğle namazı ezanı
3. **ikindi_ezan.mp3** - İkindi namazı ezanı
4. **aksam_ezan.mp3** - Akşam namazı ezanı
5. **yatsi_ezan.mp3** - Yatsı namazı ezanı

### Ses Dosyası Gereksinimleri:

- **Format:** MP3 (önerilen) veya WAV
- **Süre:** 30-60 saniye arası (tam ezan okunması)
- **Kalite:** 128kbps veya üzeri
- **Boyut:** Dosya başına max 5MB

### Örnek Dosya Yapısı:

```
assets/
  sounds/
    sabah_ezan.mp3
    ogle_ezan.mp3
    ikindi_ezan.mp3
    aksam_ezan.mp3
    yatsi_ezan.mp3
```

## Kullanım

Bu ses dosyaları bildirim ayarlarında her vakit için ayrı ayrı seçilebilir olacak.

## Alternatif İsimler (İsteğe bağlı):

Eğer farklı isimler kullanmak isterseniz, kodda aşağıdaki değişiklikleri yapın:

```dart
// services/notification_service.dart içinde
const Map<String, String> ezanSounds = {
  'fajr': 'sabah_ezan.mp3',
  'dhuhr': 'ogle_ezan.mp3',
  'asr': 'ikindi_ezan.mp3',
  'maghrib': 'aksam_ezan.mp3',
  'isha': 'yatsi_ezan.mp3',
};
```

## Test Etme

Ses dosyalarını ekledikten sonra uygulamayı yeniden çalıştırın:

```bash
flutter run
```

Bildirim ayarlarından farklı vakitler için farklı ezan sesleri seçebilirsiniz.