// Test script to verify AlAdhan API accessibility
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('🧪 Testing AlAdhan API...\n');

  // Test basic connectivity
  const testUrl = 'https://api.aladhan.com/v1/timings/21-01-2026?latitude=41.0082&longitude=28.9784&method=13';
  
  try {
    print('📡 Sending request to: $testUrl');
    
    final response = await http.get(Uri.parse(testUrl)).timeout(
      const Duration(seconds: 10),
    );

    print('✅ Response Status: ${response.statusCode}');
    print('✅ Response Headers: ${response.headers}');
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      
      print('\n✅ Response Code: ${json['code']}');
      print('✅ Response Status: ${json['status']}');
      
      final data = json['data'] as Map<String, dynamic>? ?? {};
      print('✅ Data keys: ${data.keys.toList()}');
      
      final timings = data['timings'] as Map<String, dynamic>? ?? {};
      print('✅ Timings count: ${timings.length}');
      print('✅ Timings: $timings\n');
      
      // Verify all 5 essential prayers
      const essentialPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
      print('Checking essential prayers:');
      for (final prayer in essentialPrayers) {
        if (timings.containsKey(prayer)) {
          print('  ✅ $prayer: ${timings[prayer]}');
        } else {
          print('  ❌ $prayer: MISSING!');
        }
      }
    } else {
      print('❌ Error Status: ${response.statusCode}');
      print('❌ Response Body: ${response.body}');
    }
  } catch (e, stacktrace) {
    print('❌ Error: $e');
    print(stacktrace);
  }
}
