# Google Play Yayın Sayfası

Son güncelleme: 26 Mayıs 2026

Bu dosya, `Ezanlar` uygulamasını Google Play'de yayınlamak için gereken temel bilgileri tek yerde toplar.

## 1. Uygulama Kimliği

- Uygulama içi marka adı: `Ezanlar`
- Google Play adı: `Ezanlar – Namaz Vakitleri`
- Paket adı: `com.vakit.app.ezanlar`
- Sürüm adı: `1.0.0`
- Sürüm kodu: `1`
- Varsayılan dil: `Türkçe`
- Uygulama türü: `App`
- Ücretlendirme: `Free`
- İletişim e-postası: `software19951995@gmail.com`

## 2. Main Store Listing

Google Play resmi sınırları:

- Uygulama adı: en fazla `30` karakter
- Kısa açıklama: en fazla `80` karakter
- Tam açıklama: en fazla `4000` karakter

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/9859152?hl=en
- https://support.google.com/googleplay/android-developer/answer/9898842?hl=en

### 2.1 Uygulama Adı

```text
Ezanlar – Namaz Vakitleri
```

### 2.2 Kısa Açıklama

```text
Namaz vakitleri, ezan, kıble, yakın camiler ve zikirmatik tek uygulamada.
```

### 2.3 Tam Açıklama

```text
Ezanlar, günlük ibadet düzenini kolaylaştırmak için hazırlanmış pratik bir yardımcı uygulamadır.

Uygulama ile bulunduğunuz şehir veya seçtiğiniz konuma göre namaz vakitlerini takip edebilir, ezan ve hatırlatma bildirimlerini yönetebilir, kıble yönünü görebilir ve yakındaki camileri harita üzerinde inceleyebilirsiniz.

Öne çıkan özellikler:

- Güncel namaz vakitleri
- Her vakit için ayrı bildirim ayarı
- Ezan sesi açma ve kapatma seçeneği
- 5 dakika veya 15 dakika önce hatırlatma
- Kıble yönü ekranı
- Yakındaki camileri listeleme ve haritada gösterme
- Ana ekran widget desteği
- Zikirmatik
- Türkçe, İngilizce ve Arapça dil desteği

Bildirimler ve ezan ayarları kullanıcı tercihlerine göre çalışır. Cihaz üreticisinin pil optimizasyonu, tam zamanlı alarm ayarları veya bildirim kısıtlamaları bazı telefonlarda zamanlamayı etkileyebilir.

Namaz vakitleri ve konumla ilgili bazı veriler üçüncü taraf servislerden alınabilir. Bu nedenle gerektiğinde yerel resmi takvim veya cami duyuruları ile karşılaştırma yapılması tavsiye edilir.

Destek ve gizlilik bilgileri uygulama içindeki “Destek ve Gizlilik” bölümünde yer alır.
```

## 3. Kategori ve Mağaza Ayarları

- Uygulama mı / oyun mu: `Uygulama`
- Kategori önerisi: `Lifestyle`
- Reklam var mı: `Hayır`
- Uygulama erişimi: `Hayır, giriş zorunluluğu yok`

Not:
- `Lifestyle` bu uygulama için en uygun görünen kategoridir.
- Uygulama giriş ekranı, üyelik, kapalı içerik veya test hesabı istemediği için `App access` bölümünde genelde ek açıklama gerekmez.

## 4. App Content Önerileri

Bu bölüm Play Console içindeki `App content` alanı için hazırlanmıştır.

### 4.1 Privacy Policy

Gerekli:
- Her uygulama için herkese açık bir gizlilik politikası URL'si
- PDF olmamalı
- Aktif, herkese açık, coğrafi engelli olmayan bir URL olmalı
- Uygulama adı veya geliştirici adı politikada görünmeli

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/10144311?hl=en

Hazır dosya:
- [PRIVACY_POLICY.md](C:/Users/Lenovo/Desktop/Neuer%20Ordner/namzappleri/namazvaktim/namaz_vakitleri/PRIVACY_POLICY.md)

Yayın için URL alanına koymanız gereken:

```text
https://SIZIN-ALAN-ADINIZ/privacy-policy
```

### 4.2 Data Safety

Bu uygulamanın mevcut koduna göre en güvenli beyan yaklaşımı:

- `Precise location`: `Collected`
- `Approximate location`: `Collected`
- Kullanım amacı: `App functionality`
- Paylaşım durumu: `Shared`

Gerekçe:
- Konum bilgisi, namaz vakitleri ve yakındaki camiler için üçüncü taraf servislere gönderilebiliyor.
- Bu nedenle konum verisini `not collected` veya `not shared` olarak işaretlemek risklidir.

Önemli not:
- Bu uygulamada kullanıcı hesabı, reklam SDK'sı veya analitik için açık bir yapı görünmüyor.
- Yine de Data safety formunu doldurmadan önce son release bundle içindeki tüm SDK'ları ayrıca kontrol edin.

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/10787469?hl=en

### 4.3 Content Rating

Yapılması gereken:
- IARC anketini doldur

Önerilen sonuç:
- Büyük ihtimalle `Everyone` / düşük yaş derecesi çıkar

Neden:
- Uygulama ibadet, konum, vakit, kıble ve yardımcı araçlardan oluşuyor
- Şiddet, kumar, yetişkin içerik veya yüksek riskli tema görünmüyor

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/9898843?hl=en

### 4.4 Target Audience

Önerilen seçim:

- `13–15`
- `16–17`
- `18+`

Önerilen beyan:

```text
This app is not primarily directed to children.
```

Neden:
- Çocuk hedefli seçimler Families politikasını daha sıkı hale getirir
- Bu uygulama genel kullanıcı kitlesine yönelik dini yardımcı araç kategorisinde daha güvenli konumlanır

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/9867159?hl=en

### 4.5 Ads

Önerilen seçim:

- `No, my app does not contain ads`

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/9857753?hl=en

### 4.6 App Access

Önerilen seçim:

- `All functionality is available without special access`

Not:
- Uygulamada giriş, test hesabı veya kapalı alan akışı görünmüyor.

## 5. Grafik ve Görsel Gereksinimleri

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/1078870?hl=en

### 5.1 Uygulama Simgesi

- Format: `32-bit PNG`
- Boyut: `512 x 512`
- Maksimum dosya boyutu: `1024 KB`

### 5.2 Feature Graphic

- Format: `JPG` veya `24-bit PNG`
- Boyut: `1024 x 500`

### 5.3 Ekran Görüntüleri

Zorunlu minimum:

- En az `2` ekran görüntüsü
- Format: `JPEG` veya `24-bit PNG`
- Minimum ölçü: `320 px`
- Maksimum ölçü: `3840 px`

Şiddetle önerilen:

- Telefon için en az `4` dikey ekran görüntüsü
- Boyut: `1080 x 1920` veya daha yüksek

### 5.4 Video

- Zorunlu değil
- Varsa reklam içermemeli

## 6. Teknik Yayın Hazırlığı

### 6.1 Yükleme Formatı

Google Play için önerilen yükleme:

- `Android App Bundle (.aab)`

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/9859152?hl=en

### 6.2 Manifestte Görünen İzinler

Projede görünen başlıca Android izinleri:

- `INTERNET`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `POST_NOTIFICATIONS`
- `SCHEDULE_EXACT_ALARM`
- `USE_EXACT_ALARM`
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- `ACCESS_NOTIFICATION_POLICY`
- `WAKE_LOCK`
- `VIBRATE`
- `USE_FULL_SCREEN_INTENT`
- `RECEIVE_BOOT_COMPLETED`

Not:
- Bu izinler mağaza incelemesinde açıklamalarınızla tutarlı olmalı.

### 6.3 High-risk Permission Declaration

Şu anki görünüme göre:

- SMS
- Call Log
- Background location

gibi ek beyan gerektiren yüksek riskli izinler görünmüyor.

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/9214102?hl=en

## 7. Destek ve Geliştirici Bilgileri

Play Console'da doldurulacak:

- Contact email: `software19951995@gmail.com`
- Website: `varsa ekleyin`
- Privacy Policy URL: `zorunlu`

Not:
- Google, e-posta adresini zorunlu tutar
- Web sitesi zorunlu olmasa da önerilir

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/9859152?hl=en

## 8. Yeni Kişisel Geliştirici Hesabı Notu

Eğer geliştirici hesabınız kişisel hesap olarak yeni açıldıysa, production'a geçmeden önce Google Play bazı ek test veya doğrulama adımları isteyebilir.

Kaynak:
- https://support.google.com/googleplay/android-developer/answer/9859454?hl=en
- https://support.google.com/googleplay/android-developer/answer/6112435?hl=en

## 9. Son Kontrol Listesi

Yayınlamadan önce tek tek işaretleyin:

- [ ] Uygulama içi ad `Ezanlar`
- [ ] Google Play adı `Ezanlar – Namaz Vakitleri`
- [ ] Paket adı `com.vakit.app.ezanlar`
- [ ] Kısa açıklama girildi
- [ ] Tam açıklama girildi
- [ ] İletişim e-postası `software19951995@gmail.com`
- [ ] Gizlilik politikası web URL'si eklendi
- [ ] En az 2 ekran görüntüsü yüklendi
- [ ] Feature graphic hazırlandı
- [ ] İçerik derecelendirme anketi tamamlandı
- [ ] Data safety formu dolduruldu
- [ ] Ads declaration `No` olarak kontrol edildi
- [ ] App access bölümü kontrol edildi
- [ ] Release `.aab` yüklendi
- [ ] İç test veya kapalı testte cihaz üstünde bildirim ve ezan kontrol edildi
- [ ] Privacy policy içindeki iletişim adresi güncel

## 10. Bu Proje İçindeki İlgili Dosyalar

- [PRIVACY_POLICY.md](C:/Users/Lenovo/Desktop/Neuer%20Ordner/namzappleri/namazvaktim/namaz_vakitleri/PRIVACY_POLICY.md)
- [support_legal_screen.dart](C:/Users/Lenovo/Desktop/Neuer%20Ordner/namzappleri/namazvaktim/namaz_vakitleri/lib/screens/support_legal_screen.dart)
- [settings_screen.dart](C:/Users/Lenovo/Desktop/Neuer%20Ordner/namzappleri/namazvaktim/namaz_vakitleri/lib/screens/settings_screen.dart)
- [AndroidManifest.xml](C:/Users/Lenovo/Desktop/Neuer%20Ordner/namzappleri/namazvaktim/namaz_vakitleri/android/app/src/main/AndroidManifest.xml)
- [build.gradle.kts](C:/Users/Lenovo/Desktop/Neuer%20Ordner/namzappleri/namazvaktim/namaz_vakitleri/android/app/build.gradle.kts)
