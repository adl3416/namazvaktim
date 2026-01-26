import 'package:flutter/material.dart';

class NamazVakitleriAnaSayfa extends StatelessWidget {
  const NamazVakitleriAnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 1. KATMAN: Sayım Ekranı & Lokasyon
          _buildVakitKatmani(
            vakitAdi: "VELBERT",
            vakitSaati: "1 sa 15 dk",
            renk: const Color(0xFFE3F2FD),
            yaziRengi: const Color(0xFF0D47A1),
            isSayim: true,
          ),
          // 2. KATMAN: İmsak
          _buildVakitKatmani(
            vakitAdi: "İmsak",
            vakitSaati: "06:24",
            renk: const Color(0xFFBBDEFB),
            yaziRengi: const Color(0xFF0D47A1),
          ),
          // 3. KATMAN: Güneş
          _buildVakitKatmani(
            vakitAdi: "Güneş",
            vakitSaati: "08:14",
            renk: const Color(0xFF90CAF9),
            yaziRengi: const Color(0xFF0D47A1),
          ),
          // 4. KATMAN: Öğle
          _buildVakitKatmani(
            vakitAdi: "Öğle",
            vakitSaati: "12:49",
            renk: const Color(0xFF64B5F6), // Görseldeki ana mavi
            yaziRengi: Colors.white,
          ),
          // 5. KATMAN: İkindi
          _buildVakitKatmani(
            vakitAdi: "İkindi",
            vakitSaati: "14:49",
            renk: const Color(0xFF42A5F5),
            yaziRengi: Colors.white,
          ),
          // 6. KATMAN: Akşam (AKTİF VAKİT ÖRNEĞİ)
          _buildVakitKatmani(
            vakitAdi: "Akşam",
            vakitSaati: "17:13",
            renk: const Color(0xFF1E88E5),
            yaziRengi: Colors.white,
            isAktif: true, // Kenarlık ekler
          ),
          // 7. KATMAN: Yatsı
          _buildVakitKatmani(
            vakitAdi: "Yatsı",
            vakitSaati: "18:51",
            renk: const Color(0xFF1565C0),
            yaziRengi: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildVakitKatmani({
    required String vakitAdi,
    required String vakitSaati,
    required Color renk,
    required Color yaziRengi,
    bool isSayim = false,
    bool isAktif = false,
  }) {
    return Expanded(
      flex: 1,
      child: Container(
        decoration: BoxDecoration(
          color: renk,
          // Aktif vakit için görseldeki gibi yumuşak bir çerçeve
          border: isAktif
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 2)
              : null,
          borderRadius: isAktif ? BorderRadius.circular(12) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              vakitAdi,
              style: TextStyle(
                color: yaziRengi,
                fontSize: isSayim ? 18 : 20,
                fontWeight: isSayim ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
            Text(
              vakitSaati,
              style: TextStyle(
                color: yaziRengi,
                fontSize: isSayim ? 32 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
