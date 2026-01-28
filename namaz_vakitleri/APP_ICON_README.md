# App Icon Kurulumu

## Adım 1: Logo PNG Dosyasını Yerleştirme
`assets/images/` klasörüne `app_icon.png` adıyla uygulamanızın logosunu yerleştirin.

**Gereksinimler:**
- PNG formatında olmalı
- Şeffaf arka plan (transparent background)
- Kare format (1:1 aspect ratio)
- Minimum 512x512 piksel çözünürlük
- Maksimum 1024x1024 piksel çözünürlük
- **Kenar boşlukları otomatik olarak düzeltilecek** (remove_alpha parametresi aktif)

## Adım 2: Paketleri Güncelleme
Terminal/Command Prompt'ta aşağıdaki komutu çalıştırın:

```bash
flutter pub get
```

## Adım 3: App Icon Oluşturma
Aşağıdaki komutu çalıştırarak tüm platformlar için icon'ları oluşturun:

```bash
flutter pub run flutter_launcher_icons
```

## Adım 4: Uygulamayı Çalıştırma
Icon'lar oluşturulduktan sonra uygulamayı yeniden çalıştırın:

```bash
flutter run
```

## Icon Özellikleri

- **Android**: Adaptive icon desteği (arka plan beyaz, logo önde)
- **iOS**: Alpha kanalları kaldırılmış, optimize edilmiş
- **Web**: Mavi tema rengi (#2196F3)
- **Windows**: 48x48 piksel boyutunda

## Sorun Giderme

Eğer icon oluşturma sırasında hata alırsanız:
1. PNG dosyasının `assets/images/app_icon.png` yolunda olduğundan emin olun
2. PNG dosyasının şeffaf arka plana sahip olduğunu kontrol edin
3. `flutter clean` komutunu çalıştırıp tekrar deneyin