import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportLegalScreen extends StatelessWidget {
  const SupportLegalScreen({super.key, required this.language});

  final String language;

  static final Uri _supportEmailUri = Uri(
    scheme: 'mailto',
    path: 'software19951995@gmail.com',
    query: 'subject=Namaz Vakitim Destek',
  );

  String _text({
    required String tr,
    required String en,
    required String ar,
  }) {
    switch (language) {
      case 'tr':
        return tr;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  Future<void> _launchSupportEmail(BuildContext context) async {
    if (await canLaunchUrl(_supportEmailUri)) {
      await launchUrl(_supportEmailUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              tr: 'E-posta uygulaması açılamadı.',
              en: 'Could not open the email app.',
              ar: 'تعذر فتح تطبيق البريد الإلكتروني.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E1A16),
        title: Text(
          _text(
            tr: 'Destek ve Gizlilik',
            en: 'Support and Privacy',
            ar: 'الدعم والخصوصية',
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6F0E6),
              Color(0xFFE7DCCB),
              Color(0xFFF9F6F1),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _HeaderCard(
              title: _text(
                tr: 'Bilmeniz gereken temel bilgiler',
                en: 'Key information you should know',
                ar: 'أهم المعلومات التي ينبغي معرفتها',
              ),
              subtitle: _text(
                tr: 'Burada iletişim, gizlilik, konum kullanımı ve bildirimlerle ilgili kısa ve açık bilgiler yer alır.',
                en: 'Here you can find short and clear information about contact, privacy, location use, and notifications.',
                ar: 'هنا ستجد معلومات مختصرة وواضحة عن التواصل والخصوصية واستخدام الموقع والإشعارات.',
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: _text(
                tr: 'İletişim',
                en: 'Contact',
                ar: 'التواصل',
              ),
              body: _text(
                tr: 'Destek almak, soru sormak veya veriyle ilgili talepte bulunmak için bize e-posta gönderebilirsiniz.',
                en: 'You can email us for support, questions, or data-related requests.',
                ar: 'يمكنك مراسلتنا للحصول على الدعم أو لطرح الأسئلة أو لطلبات تتعلق بالبيانات.',
              ),
              child: FilledButton.icon(
                onPressed: () => _launchSupportEmail(context),
                icon: const Icon(Icons.email_outlined),
                label: const Text('software19951995@gmail.com'),
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: _text(
                tr: 'Hangi veriler kullanılır?',
                en: 'What data is used?',
                ar: 'ما البيانات المستخدمة؟',
              ),
              body: _text(
                tr: 'Uygulama; konum, seçtiğiniz şehir, bildirim tercihleri, tema, dil ve zikirmatik gibi ayarları kullanabilir. Bu bilgiler uygulamanın çalışması için gereklidir.',
                en: 'The app may use location, selected city, notification preferences, theme, language, and zikirmatik settings. This information is needed for the app to work properly.',
                ar: 'قد يستخدم التطبيق الموقع والمدينة المختارة وتفضيلات الإشعارات والمظهر واللغة وإعدادات الذكر. هذه المعلومات مطلوبة لعمل التطبيق بشكل صحيح.',
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: _text(
                tr: 'Konum neden isteniyor?',
                en: 'Why is location needed?',
                ar: 'لماذا يُطلب الموقع؟',
              ),
              body: _text(
                tr: 'Konum; bulunduğunuz şehri belirlemek, kıble yönünü göstermek ve yakındaki camileri bulmak için kullanılabilir. İsterseniz manuel şehir seçerek konumu kullanmadan da devam edebilirsiniz.',
                en: 'Location may be used to detect your city, show qibla direction, and find nearby mosques. You can also continue by selecting a city manually instead of using location.',
                ar: 'قد يُستخدم الموقع لتحديد مدينتك وعرض اتجاه القبلة والعثور على المساجد القريبة. ويمكنك أيضًا المتابعة باختيار مدينة يدويًا دون استخدام الموقع.',
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: _text(
                tr: 'Bildirimler ve ezan',
                en: 'Notifications and adhan',
                ar: 'الإشعارات والأذان',
              ),
              body: _text(
                tr: 'Bildirimler ve ezan sesleri, tamamen sizin ayarlarınıza göre çalışır. Cihazınızın bildirim, pil veya tam zamanlı alarm kısıtlamaları bazı telefonlarda zamanlamayı etkileyebilir.',
                en: 'Notifications and adhan sounds work according to your settings. On some phones, device restrictions such as notification, battery, or exact alarm settings may affect timing.',
                ar: 'تعمل الإشعارات وأصوات الأذان وفقًا لإعداداتك. في بعض الأجهزة قد تؤثر قيود الإشعارات أو البطارية أو التنبيهات الدقيقة على التوقيت.',
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: _text(
                tr: 'Üçüncü taraf servisler',
                en: 'Third-party services',
                ar: 'خدمات الأطراف الثالثة',
              ),
              body: _text(
                tr: 'Namaz vakitleri ve harita/cami verileri bazı dış servislerden alınabilir. Bu servislerin geçici olarak yavaşlaması veya hata vermesi uygulamadaki sonuçları etkileyebilir.',
                en: 'Prayer time and map/mosque data may come from external services. If those services are slow or temporarily unavailable, results in the app may be affected.',
                ar: 'قد تأتي بيانات أوقات الصلاة والخرائط والمساجد من خدمات خارجية. وإذا كانت هذه الخدمات بطيئة أو غير متاحة مؤقتًا فقد يتأثر ما يظهر في التطبيق.',
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: _text(
                tr: 'Verileriniz nerede tutulur?',
                en: 'Where is your data stored?',
                ar: 'أين يتم حفظ بياناتك؟',
              ),
              body: _text(
                tr: 'Ayarlarınızın büyük kısmı cihazınızda yerel olarak tutulur. Uygulamayı silmeniz veya uygulama verilerini temizlemeniz durumunda bu yerel kayıtlar kaldırılabilir.',
                en: 'Most of your settings are stored locally on your device. If you uninstall the app or clear app data, these local records may be removed.',
                ar: 'يتم حفظ معظم إعداداتك محليًا على جهازك. وإذا حذفت التطبيق أو مسحت بياناته فقد تتم إزالة هذه السجلات المحلية.',
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: _text(
                tr: 'Doğruluk hakkında',
                en: 'About accuracy',
                ar: 'حول الدقة',
              ),
              body: _text(
                tr: 'Namaz vakitleri, kıble yönü ve bildirim zamanları; cihaz saati, konum doğruluğu, internet bağlantısı ve dış veri kaynaklarından etkilenebilir. Gerekli gördüğünüzde yerel resmi takvim veya cami duyurularıyla karşılaştırma yapmanız önerilir.',
                en: 'Prayer times, qibla direction, and notification timing can be affected by device time, location accuracy, internet connection, and external data sources. When needed, compare them with local official calendars or mosque announcements.',
                ar: 'قد تتأثر أوقات الصلاة واتجاه القبلة وتوقيت الإشعارات بوقت الجهاز ودقة الموقع والاتصال بالإنترنت ومصادر البيانات الخارجية. عند الحاجة يُنصح بمقارنتها مع التقويمات الرسمية المحلية أو إعلانات المساجد.',
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: _text(
                tr: 'Haklarınız',
                en: 'Your rights',
                ar: 'حقوقك',
              ),
              body: _text(
                tr: 'Veriyle ilgili soru sorma, düzeltme isteme veya silme talebi gönderme hakkınız vardır. Bunun için yukarıdaki e-posta adresinden bize ulaşabilirsiniz.',
                en: 'You have the right to ask questions about your data, request corrections, or request deletion. You can contact us through the email address above.',
                ar: 'لديك الحق في طرح الأسئلة حول بياناتك أو طلب تصحيحها أو حذفها. يمكنك التواصل معنا عبر البريد الإلكتروني أعلاه.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E),
            Color(0xFF14B8A6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_rounded, color: Colors.white, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.body,
    this.child,
  });

  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.88)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1A16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF655B51),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 14),
            child!,
          ],
        ],
      ),
    );
  }
}
