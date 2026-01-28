import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/color_system.dart';
import '../config/localization.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';

class CitySelectionScreen extends StatefulWidget {
  final String countryCode;
  final String countryName;

  const CitySelectionScreen({
    super.key,
    required this.countryCode,
    required this.countryName,
  });

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  final Map<String, List<String>> _citiesByCountry = {
    'TR': [
      'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Adana', 'Gaziantep',
      'Konya', 'Kayseri', 'Samsun', 'Denizli', 'Eskişehir', 'Sakarya', 'Trabzon',
      'Erzurum', 'Malatya', 'Van', 'Diyarbakır', 'Şanlıurfa', 'Batman', 'Mardin',
      'Siirt', 'Şırnak', 'Hakkari', 'Ağrı', 'Kars', 'Iğdır', 'Ardahan', 'Artvin',
      'Rize', 'Giresun', 'Ordu', 'Amasya', 'Tokat', 'Çorum', 'Yozgat', 'Sivas',
      'Kırşehir', 'Nevşehir', 'Niğde', 'Aksaray', 'Kırıkkale', 'Çankırı', 'Karabük',
      'Bartın', 'Zonguldak', 'Düzce', 'Bolu', 'Yalova', 'Kocaeli', 'Sakarya',
      'Tekirdağ', 'Edirne', 'Kırklareli', 'Çanakkale', 'Balıkesir', 'Çanakkale',
      'Manisa', 'Kütahya', 'Uşak', 'Aydın', 'İzmir', 'Muğla', 'Denizli', 'Burdur',
      'Isparta', 'Afyonkarahisar', 'Kütahya', 'Eskişehir', 'Bilecik', 'Sakarya'
    ],
    'DE': [
      'Berlin', 'Hamburg', 'München', 'Köln', 'Frankfurt', 'Stuttgart', 'Düsseldorf',
      'Dortmund', 'Essen', 'Leipzig', 'Bremen', 'Dresden', 'Hannover', 'Nürnberg',
      'Duisburg', 'Bochum', 'Wuppertal', 'Bielefeld', 'Bonn', 'Münster', 'Karlsruhe',
      'Mannheim', 'Augsburg', 'Wiesbaden', 'Gelsenkirchen', 'Mönchengladbach',
      'Braunschweig', 'Chemnitz', 'Kiel', 'Aachen', 'Halle', 'Magdeburg', 'Freiburg',
      'Krefeld', 'Lübeck', 'Oberhausen', 'Erfurt', 'Mainz', 'Rostock', 'Kassel',
      'Hagen', 'Hamm', 'Saarbrücken', 'Mülheim', 'Potsdam', 'Ludwigshafen',
      'Oldenburg', 'Leverkusen', 'Osnabrück', 'Solingen', 'Heidelberg', 'Herne',
      'Neuss', 'Darmstadt', 'Paderborn', 'Regensburg', 'Ingolstadt', 'Würzburg',
      'Fürth', 'Ulm', 'Heilbronn', 'Pforzheim', 'Wolfsburg', 'Göttingen', 'Bottrop',
      'Reutlingen', 'Koblenz', 'Bremerhaven', 'Bergisch Gladbach', 'Jena', 'Remscheid',
      'Erlangen', 'Moers', 'Siegen', 'Hildesheim', 'Salzgitter', 'Gütersloh', 'Kaiserslautern'
    ],
    'SA': [
      'Riyad', 'Ceddah', 'Mekke', 'Medine', 'Dammam', 'Taif', 'Tabuk', 'Buraydah',
      'Khamis Mushait', 'Hail', 'Al Kharj', 'Najran', 'Al Qatif', 'Jubail',
      'Abha', 'Yanbu', 'Al Majma\'ah', 'Unayzah', 'Khobar', 'Dhahran', 'Arar',
      'Sakakah', 'Jizan', 'Qurayyat', 'Rafha', 'Al Duwadimi', 'Bisha', 'Wadi ad-Dawasir',
      'Al Bahah', 'Ad Dilam', 'Ad Diriyah', 'Afif', 'Al Mithnab', 'Al Ula', 'As Sulayyil',
      'Az Zulfi', 'Badr Hunayn', 'Baljurashi', 'Birq', 'Duba', 'Farasan', 'Hawtat Bani Tamim',
      'Hotat Sudair', 'Huraymila', 'Layla', 'Muzahmiyya', 'Qaisumah', 'Qatif', 'Rabigh',
      'Rijal Alma', 'Rumah', 'Sabya', 'Safwa', 'Sajir', 'Samtah', 'Sharurah', 'Shaqra',
      'Sulayyil', 'Tabarjal', 'Tamrah', 'Tanomah', 'Tarut', 'Tayma', 'Thadiq', 'Thar',
      'Turaif', 'Umm Lajj', 'Umm as Sahik', 'Uyun al Jiwa', 'Wajh', 'Zahran al Janub'
    ],
    'AE': [
      'Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Ras Al Khaimah', 'Fujairah',
      'Umm Al Quwain', 'Al Ain', 'Dibba Al-Fujairah', 'Dibba Al-Hisn', 'Khor Fakkan',
      'Ar-Rams', 'Delma Island', 'Madinat Zayed', 'Ruwais', 'Liwa Oasis', 'Ghiyathi',
      'Mirfa', 'Zayed City', 'Sweihan', 'Habshan', 'Al Madam', 'Al Jazirah Al Hamra',
      'Al Khatim', 'Al Mirfa', 'Al Yahar', 'Al Falah', 'Al Quaa', 'Al Samha',
      'Al Wathba', 'Al Rafaah', 'Al Hamriyah', 'Al Rafaah', 'Al Manama', 'Al Aryam',
      'Al Dhaid', 'Al Hamriyah', 'Al Lisaili', 'Al Madam', 'Al Rafaah', 'Al Shahama',
      'Al Yahar', 'Dafan Al Zafaran', 'Falaj Al Mualla', 'Ghayathi', 'Hatta',
      'Kalba', 'Khatt', 'Masafi', 'Mileiha', 'Muzayri', 'Ras Al Khaimah City',
      'Sila', 'Zayed City'
    ],
    'US': [
      'New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia',
      'San Antonio', 'San Diego', 'Dallas', 'San Jose', 'Austin', 'Jacksonville',
      'Fort Worth', 'Columbus', 'Indianapolis', 'Charlotte', 'San Francisco',
      'Seattle', 'Denver', 'Boston', 'El Paso', 'Detroit', 'Nashville', 'Portland',
      'Memphis', 'Oklahoma City', 'Las Vegas', 'Louisville', 'Baltimore', 'Milwaukee',
      'Albuquerque', 'Tucson', 'Fresno', 'Sacramento', 'Mesa', 'Kansas City',
      'Atlanta', 'Long Beach', 'Colorado Springs', 'Raleigh', 'Miami', 'Virginia Beach',
      'Omaha', 'Oakland', 'Minneapolis', 'Tulsa', 'Arlington', 'Tampa', 'New Orleans',
      'Wichita', 'Cleveland', 'Bakersfield', 'Aurora', 'Anaheim', 'Honolulu', 'Santa Ana',
      'Corpus Christi', 'Riverside', 'Lexington', 'Stockton', 'Henderson', 'Saint Paul',
      'St. Louis', 'Cincinnati', 'Pittsburgh', 'Greensboro', 'Anchorage', 'Plano',
      'Lincoln', 'Orlando', 'Irvine', 'Newark', 'Durham', 'Chula Vista', 'Toledo',
      'Fort Wayne', 'St. Petersburg', 'Laredo', 'Jersey City', 'Chandler', 'Madison',
      'Lubbock', 'Scottsdale', 'Reno', 'Buffalo', 'Gilbert', 'Glendale', 'North Las Vegas',
      'Winston-Salem', 'Chesapeake', 'Norfolk', 'Fremont', 'Garland', 'Irving', 'Hialeah',
      'Richmond', 'Boise', 'Spokane'
    ],
    'GB': [
      'London', 'Birmingham', 'Manchester', 'Liverpool', 'Leeds', 'Sheffield',
      'Bristol', 'Newcastle upon Tyne', 'Sunderland', 'Brighton', 'Hull', 'Plymouth',
      'Stoke-on-Trent', 'Wolverhampton', 'Norwich', 'Swansea', 'Southampton',
      'Reading', 'Dundee', 'Cardiff', 'Belfast', 'Derry', 'Lisburn', 'Newtownabbey',
      'Bangor', 'Antrim', 'Downpatrick', 'Armagh', 'Londonderry', 'Coleraine',
      'Ballymena', 'Newry', 'Craigavon', 'Bangor', 'Castlereagh', 'Glasgow',
      'Edinburgh', 'Aberdeen', 'Dundee', 'Inverness', 'Stirling', 'Perth', 'Dundee',
      'Ayr', 'Kilmarnock', 'Greenock', 'Coatbridge', 'Airdrie', 'Cumbernauld',
      'Hamilton', 'East Kilbride', 'Livingston', 'Clydebank', 'Kirkintilloch',
      'Rutherglen', 'Cambuslang', 'Wishaw', 'Motherwell', 'Bellshill', 'Coatbridge',
      'Airdrie', 'Blantyre', 'Uddingston', 'Viewpark', 'Bothwell', 'Newarthill',
      'Holytown', 'Newmains', 'Shotts', 'Fauldhouse', 'Breich', 'West Calder',
      'Addiewell', 'Logan', 'Seafield', 'Blackridge', 'Armadale', 'Bathgate',
      'Whitburn', 'Fauldhouse', 'Longridge', 'West Calder', 'East Calder', 'Kirknewton',
      'Ratho', 'Queensferry', 'Dalmeny', 'South Queensferry', 'Edinburgh', 'Leith'
    ],
    'FR': [
      'Paris', 'Marseille', 'Lyon', 'Toulouse', 'Nice', 'Nantes', 'Strasbourg',
      'Montpellier', 'Bordeaux', 'Lille', 'Rennes', 'Reims', 'Le Havre', 'Saint-Étienne',
      'Toulon', 'Grenoble', 'Dijon', 'Angers', 'Nîmes', 'Villeurbanne', 'Le Mans',
      'Aix-en-Provence', 'Clermont-Ferrand', 'Brest', 'Limoges', 'Tours', 'Amiens',
      'Metz', 'Besançon', 'Orléans', 'Mulhouse', 'Rouen', 'Caen', 'Nancy', 'Saint-Denis',
      'Argenteuil', 'Roubaix', 'Dunkerque', 'Tourcoing', 'Nanterre', 'Avignon',
      'Créteil', 'Poitiers', 'Fort-de-France', 'Versailles', 'Colmar', 'Pau',
      'La Rochelle', 'Valence', 'Saint-Paul', 'Ajaccio', 'Béziers', 'Troyes',
      'Antibes', 'Cannes', 'Calais', 'Digne-les-Bains', 'Draguignan', 'Gap',
      'Grasse', 'Hyères', 'Mandelieu-la-Napoule', 'Marignane', 'Martigues', 'Meyreuil',
      'Miramas', 'Plan-de-Cuques', 'Port-de-Bouc', 'Rognac', 'Saintes-Maries-de-la-Mer',
      'Salon-de-Provence', 'Sanary-sur-Mer', 'Septèmes-les-Vallons', 'Tarascon',
      'Vitrolles', 'Velaux', 'Venelles', 'Berre-l\'Étang', 'Châteauneuf-les-Martigues',
      'Fos-sur-Mer', 'Gignac-la-Narbonnaise', 'Graveson', 'Istres', 'Lambesc',
      'Maillane', 'Meyrargues', 'Mouriès', 'Noves', 'Orgon', 'Pélissanne', 'Peyrolles-en-Provence',
      'Port-Saint-Louis-du-Rhône', 'Puyloubier', 'Rognes', 'Rousset', 'Saint-Andiol',
      'Saint-Cannat', 'Saint-Chamas', 'Saintes-Maries-de-la-Mer', 'Saint-Rémy-de-Provence',
      'Saint-Victoret', 'Salin-de-Giraud', 'Sénas', 'Trets', 'Vauvenargues', 'Vernègues',
      'Villelaure', 'Alleins', 'Ansouis', 'Aubagne', 'Auriol', 'Barbentane', 'Beaurecueil',
      'Belcodène', 'Berre-l\'Étang', 'Bouc-Bel-Air', 'Cabriès', 'Cadolive', 'Carnoux-en-Provence',
      'Carry-le-Rouet', 'Cassis', 'Ceyreste', 'Châteauneuf-le-Rouge', 'Châteauneuf-les-Martigues',
      'La Ciotat', 'Cuges-les-Pins', 'Ensuès-la-Redonne', 'Fos-sur-Mer', 'Gardanne',
      'Gignac-la-Narbonnaise', 'Graveson', 'Istres', 'Lambesc', 'Maillane', 'Meyrargues',
      'Mouriès', 'Noves', 'Orgon', 'Pélissanne', 'Peyrolles-en-Provence', 'Port-Saint-Louis-du-Rhône',
      'Puyloubier', 'Rognes', 'Rousset', 'Saint-Andiol', 'Saint-Cannat', 'Saint-Chamas',
      'Saintes-Maries-de-la-Mer', 'Saint-Rémy-de-Provence', 'Saint-Victoret', 'Salin-de-Giraud',
      'Sénas', 'Trets', 'Vauvenargues', 'Vernègues', 'Villelaure', 'Alleins', 'Ansouis',
      'Aubagne', 'Auriol', 'Barbentane', 'Beaurecueil', 'Belcodène', 'Berre-l\'Étang',
      'Bouc-Bel-Air', 'Cabriès', 'Cadolive', 'Carnoux-en-Provence', 'Carry-le-Rouet',
      'Cassis', 'Ceyreste', 'Châteauneuf-le-Rouge', 'Châteauneuf-les-Martigues', 'La Ciotat',
      'Cuges-les-Pins', 'Ensuès-la-Redonne', 'Fos-sur-Mer', 'Gardanne'
    ],
    'NL': [
      'Amsterdam', 'Rotterdam', 'The Hague', 'Utrecht', 'Eindhoven', 'Tilburg',
      'Groningen', 'Almere', 'Breda', 'Nijmegen', 'Enschede', 'Haarlem', 'Arnhem',
      'Zaanstad', 'Amersfoort', 'Apeldoorn', 'Hoofddorp', 'Maastricht', 'Leiden',
      'Dordrecht', 'Zoetermeer', 'Zwolle', 'Deventer', 'Delft', 'Alkmaar', 'Heerlen',
      'Hilversum', 'Sittard', 'Roosendaal', 'Purmerend', 'Oss', 'Schiedam', 'Spijkenisse',
      'Vlaardingen', 'Veenendaal', 'Bergen op Zoom', 'Capelle aan den IJssel', 'Assen',
      'Velsen-Zuid', 'Nieuwegein', 'Zeist', 'Hardenberg', 'Kampen', 'Lelystad', 'Barendrecht',
      'Midden-Delfland', 'Westland', 'Rijswijk', 'Papendrecht', 'Gouda', 'Culemborg',
      'Woerden', 'IJsselstein', 'Huizen', 'Naarden', 'Bussum', 'Hilversum', 'Laren',
      'Blaricum', 'Eemnes', 'Baarn', 'Soest', 'Amersfoort', 'Leusden', 'Woudenberg',
      'Rhenen', 'Veenendaal', 'Ede', 'Barneveld', 'Apeldoorn', 'Voorst', 'Lochem',
      'Berkelland', 'Bronckhorst', 'Doesburg', 'Duiven', 'Gelderland', 'Lingewaard',
      'Nijmegen', 'Overbetuwe', 'Renkum', 'Rheden', 'Rozendaal', 'Wageningen', 'West Maas en Waal',
      'Wijchen', 'Zevenaar', 'Zutphen', 'Aalten', 'Berkelland', 'Bronckhorst', 'Doetinchem',
      'Doesburg', 'Duiven', 'Gelderland', 'Lingewaard', 'Montferland', 'Nijmegen', 'Oude IJsselstreek',
      'Overbetuwe', 'Renkum', 'Rheden', 'Rozendaal', 'Wageningen', 'West Maas en Waal', 'Wijchen',
      'Zevenaar', 'Zutphen', 'Aalten', 'Berkelland', 'Bronckhorst', 'Doetinchem'
    ],
    'CA': [
      'Toronto', 'Montreal', 'Vancouver', 'Calgary', 'Edmonton', 'Ottawa', 'Winnipeg',
      'Quebec City', 'Hamilton', 'Kitchener', 'London', 'Victoria', 'Halifax', 'Oshawa',
      'Windsor', 'Saskatoon', 'Regina', 'Sherbrooke', 'Kingston', 'Thunder Bay', 'Sudbury',
      'Abbotsford', 'Saguenay', 'Levis', 'Kelowna', 'Barrie', 'Trois-Rivières', 'Guelph',
      'Moncton', 'Brantford', 'Saint John', 'Thunder Bay', 'Peterborough', 'Chatham-Kent',
      'Belleville', 'Sarnia', 'Fredericton', 'Charlottetown', 'Yellowknife', 'Iqaluit',
      'Whitehorse', 'St. John\'s', 'Happy Valley-Goose Bay', 'Corner Brook', 'Grand Falls-Windsor',
      'Gander', 'Labrador City', 'Marystown', 'Stephenville', 'Wabush', 'Buchans', 'Carbonear',
      'Clarenville', 'Deer Lake', 'Fogo Island', 'Harbour Breton', 'Harbour Grace', 'Heart\'s Content',
      'Heart\'s Delight-Islington', 'Heart\'s Desire', 'Holyrood', 'Lewisporte', 'Mount Pearl',
      'New-Wes-Valley', 'Old Perlican', 'Placentia', 'Port aux Basques', 'Port aux Choix',
      'Port au Port East', 'Port au Port West', 'Port Blandford', 'Port Hope Simpson',
      'Port Rexton', 'Port Saunders', 'Port Union', 'Portugal Cove-St. Philip\'s', 'Ramea',
      'Red Bay', 'Rencontre East', 'Rencontre West', 'Rigolet', 'Rose Blanche-Harbour le Cou',
      'St. Alban\'s', 'St. Anthony', 'St. Bride\'s', 'St. George\'s', 'St. Jacques-Coomb\'s Cove',
      'St. John\'s', 'St. Lawrence', 'St. Lewis', 'St. Lunaire-Griquet', 'St. Mary\'s',
      'St. Paul\'s River', 'St. Shott\'s', 'St. Vincent\'s-St. Stephen\'s-Peter\'s River',
      'Sally\'s Cove', 'Sandringham', 'Seal Cove', 'South Brook', 'Springdale', 'St. Bernard\'s-Jacques Fontaine',
      'St. Brendan\'s', 'St. Brendans', 'St. Bride\'s', 'St. George\'s', 'St. Jacques-Coomb\'s Cove',
      'St. John\'s', 'St. Lawrence', 'St. Lewis', 'St. Lunaire-Griquet', 'St. Mary\'s',
      'St. Paul\'s River', 'St. Shott\'s', 'St. Vincent\'s-St. Stephen\'s-Peter\'s-Peter\'s River',
      'Sally\'s Cove', 'Sandringham', 'Seal Cove', 'South Brook', 'Springdale', 'Summerford',
      'Terra Nova', 'Torbay', 'Trepassey', 'Trinity Bay North', 'Twillingate', 'Wabana',
      'Wesleyville', 'Whitbourne', 'Winterton', 'Witless Bay', 'Woodstock', 'York Harbour'
    ],
    'AU': [
      'Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide', 'Gold Coast', 'Newcastle',
      'Canberra', 'Wollongong', 'Logan City', 'Geelong', 'Hobart', 'Townsville', 'Ipswich',
      'Cairns', 'Toowoomba', 'Darwin', 'Ballarat', 'Bendigo', 'Albury', 'Launceston',
      'Mackay', 'Rockhampton', 'Bunbury', 'Bundaberg', 'Hervey Bay', 'Wagga Wagga',
      'Coffs Harbour', 'Dubbo', 'Lismore', 'Mandurah', 'Kalgoorlie', 'Albany', 'Karratha',
      'Mount Isa', 'Tennant Creek', 'Katherine', 'Palmerston', 'Alice Springs', 'Katherine',
      'Tennant Creek', 'Yulara', 'Uluru', 'Coober Pedy', 'Woomera', 'Ceduna', 'Kimba',
      'Kimba', 'Port Augusta', 'Whyalla', 'Port Lincoln', 'Kimba', 'Woomera', 'Roxby Downs',
      'Andamooka', 'Leigh Creek', 'Copley', 'Hawker', 'Wilpena', 'Kimba', 'Port Augusta',
      'Whyalla', 'Port Lincoln', 'Tumby Bay', 'Kimba', 'Woomera', 'Roxby Downs', 'Andamooka',
      'Leigh Creek', 'Copley', 'Hawker', 'Wilpena', 'Marree', 'Oodnadatta', 'William Creek',
      'Birdsville', 'Bedourie', 'Boulia', 'Burketown', 'Camoweal', 'Camooweal', 'Cloncurry',
      'Dajarra', 'Dulkaninna', 'Gregory', 'Hughenden', 'Julia Creek', 'Karumba', 'Kynuna',
      'McKinlay', 'Normanton', 'Richmond', 'Winton', 'Adelaide River', 'Batchelor', 'Berry Springs',
      'Darwin River', 'Douglas-Daly', 'Dundee Beach', 'Dundee Forest', 'Dundee Beach', 'Dundee Forest',
      'Humpty Doo', 'Katherine', 'Larrakeyah', 'Leanyer', 'Manton', 'McMinns Lagoon', 'Mickett Creek',
      'Millner', 'Nightcliff', 'Palmerston', 'Parap', 'Pine Creek', 'Tennant Creek', 'The Gap',
      'Tivendale', 'Wagait Beach', 'Wagaman', 'Woolner', 'Wulagi', 'Yulara', 'Uluru', 'Coober Pedy',
      'Woomera', 'Ceduna', 'Kimba', 'Port Augusta', 'Whyalla', 'Port Lincoln', 'Tumby Bay',
      'Kimba', 'Woomera', 'Roxby Downs', 'Andamooka', 'Leigh Creek', 'Copley', 'Hawker',
      'Wilpena', 'Marree', 'Oodnadatta', 'William Creek', 'Birdsville', 'Bedourie', 'Boulia',
      'Burketown', 'Camoweal', 'Camooweal', 'Cloncurry', 'Dajarra', 'Dulkaninna', 'Gregory',
      'Hughenden', 'Julia Creek', 'Karumba', 'Kynuna', 'McKinlay', 'Normanton', 'Richmond',
      'Winton', 'Adelaide River', 'Batchelor', 'Berry Springs', 'Darwin River', 'Douglas-Daly',
      'Dundee Beach', 'Dundee Forest', 'Humpty Doo', 'Katherine', 'Larrakeyah', 'Leanyer',
      'Manton', 'McMinns Lagoon', 'Mickett Creek', 'Millner', 'Nightcliff', 'Palmerston',
      'Parap', 'Pine Creek', 'Tennant Creek', 'The Gap', 'Tivendale', 'Wagait Beach', 'Wagaman',
      'Woolner', 'Wulagi'
    ],
  };

  List<String> get _filteredCities {
    final cities = _citiesByCountry[widget.countryCode] ?? [];
    if (_searchQuery.isEmpty) {
      return cities;
    }
    return cities
        .where((city) =>
            city.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _selectCity(String city) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prayerProvider = context.read<PrayerProvider>();

      // Update prayer times for new location
      await prayerProvider.setLocation(city, widget.countryCode);

      // Go back to home screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şehir güncellenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.read<AppSettings>().language;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.countryName} - ${AppLocalizations.translate('search_city', locale)}',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '${widget.countryName} şehrini ara...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkTextLight : AppColors.textLight,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkAccentPrimary
                        : AppColors.accentPrimary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Cities List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isDark
                          ? AppColors.darkAccentPrimary
                          : AppColors.accentPrimary,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        title: Text(
                          city,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        onTap: () => _selectCity(city),
                        trailing: Icon(
                          Icons.location_on,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}