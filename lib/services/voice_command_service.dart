import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/market_screen.dart';
import '../screens/disease_screen.dart';
import '../screens/disease_gallery_screen.dart';
import '../screens/crop_screen.dart';
import '../screens/crop_calendar_screen.dart';
import '../screens/assistant_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/history_screen.dart';
import '../screens/yield_profit_screen.dart';
import '../screens/schemes_screen.dart';
import '../screens/risk_alerts_screen.dart';
import '../screens/community_screen.dart';
import '../screens/farm_map_screen.dart';
import '../screens/fertilizer_screen.dart';
import '../screens/water_mediation_screen.dart';
import '../screens/machinery_screen.dart';
import '../screens/labour_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/contracts_screen.dart';
import '../screens/specialized_farming_screen.dart';
import '../screens/hydroponics_screen.dart';
import '../screens/organic_hydroponics_screen.dart';
import '../screens/poultry_screen.dart';
import '../screens/dairy_livestock_screen.dart';
import '../screens/aquaculture_screen.dart';
import '../screens/horticulture_screen.dart';

class VoiceCommandResult {
  final Widget? screen;
  final String? routeName;
  final String screenLabel;
  final bool isPop;

  VoiceCommandResult({
    this.screen,
    this.routeName,
    required this.screenLabel,
    this.isPop = false,
  });
}

class VoiceCommandService {
  /// Map of keywords → screen builders and multilingual labels.
  /// Fully covers all Smart Farm Services in 11 Indian languages.
  static final List<_CommandEntry> _commands = [
    // 1. Back / Previous Navigation
    _CommandEntry(
      keywords: [
        'back', 'go back', 'return', 'previous', 'close',
        'वापस', 'पीछे', 'बंद करो', // Hindi
        'వెనుకకు', 'వెనక్కి', 'మునుపటి', // Telugu
        'பின்னால்', 'திரும்பு', // Tamil
        'ಹಿಂದೆ', 'ಮರಳಿ', // Kannada
        'ফিরে', 'পেছনে', // Bengali
        'मागे', 'परत', // Marathi
        'પાછા', 'પરત', // Gujarati
        'പുറകോട്ട്', 'മടക്കം', // Malayalam
        'ਪਿੱਛੇ', 'ਵਾਪਸ', // Punjabi
        'ପଛକୁ', 'ଫେରି', // Odia
      ],
      labels: {
        'en': 'Back', 'hi': 'वापस', 'te': 'వెనుకకు',
        'ta': 'பின்னால்', 'kn': 'ಹಿಂದೆ', 'bn': 'ফিরে',
        'mr': 'मागे', 'gu': 'પાછા', 'ml': 'പുറകോട്ട്',
        'pa': 'ਪਿੱਛੇ', 'or': 'ପଛକୁ',
      },
      isPop: true,
    ),

    // 2. Jala-Mitra / Water Sharing / Canal Mediation
    _CommandEntry(
      keywords: [
        'water sharing', 'water mediation', 'jala mitra', 'jal mitra',
        'canal', 'canal flow', 'water dispute', 'smart irrigation',
        'water', 'irrigation sharing', 'water arbitration',
        // Telugu
        'జల మిత్ర', 'నీటి భాగస్వామ్యం', 'కాలువ', 'నీరు', 'నీళ్ళు', 'నీటి పంపకం',
        // Hindi
        'जल मित्र', 'पानी का बंटवारा', 'नहर', 'पानी', 'सिंचाई बंटवारा',
        // Tamil
        'தண்ணீர் பகிர்வு', 'நீர் மத்தியஸ்தம்', 'ஜல மித்ரா', 'கால்வாய்',
        // Kannada
        'ನೀರು ಹಂಚಿಕೆ', 'ಜಲ ಮಿತ್ರ', 'ಕಾಲುವೆ', 'ನೀರು',
        // Bengali
        'জল মিত্র', 'জল বণ্টন', 'খাল',
        // Marathi
        'जल मित्र', 'पाणी वाटप', 'कालवा',
        // Gujarati
        'જળ મિત્ર', 'પાણીની વહેંચણી', 'નહેર',
        // Malayalam
        'ജല മിത്ര', 'ജല വിതരണം', 'കനാൽ',
        // Punjabi
        'ਜਲ ਮਿੱਤਰ', 'ਨਹਿਰੀ ਪਾਣੀ', 'ਪਾਣੀ',
        // Odia
        'ଜଳ ମିତ୍ର', 'କେନାଲ ପାଣି', 'ପାଣି ବଣ୍ଟନ',
      ],
      labels: {
        'en': 'Jala-Mitra Water Sharing', 'hi': 'जल-मित्र पानी का बंटवारा',
        'te': 'జల-మిత్ర నీటి భాగస్వామ్యం', 'ta': 'ஜல-மித்ரா தண்ணீர் பகிர்வு',
        'kn': 'ಜಲ-ಮಿತ್ರ ನೀರು ಹಂಚಿಕೆ', 'bn': 'জলা-মিত্র জল বণ্টন',
        'mr': 'जल-मित्र पाणी वाटप', 'gu': 'જળ-મિત્ર પાણીની વહેંચણી',
        'ml': 'ജല-മിത്ര ജല വിതരണം', 'pa': 'ਜਲ-ਮਿੱਤਰ ਪਾਣੀ ਸਾਂਝ',
        'or': 'ଜଳ-ମିତ୍ର ପାଣି ବଣ୍ଟନ',
      },
      builder: () => const WaterMediationScreen(),
    ),

    // 3. Government Schemes & Subsidies (MANDATORY OFFICIAL LINKS)
    _CommandEntry(
      keywords: [
        'scheme', 'schemes', 'government schemes', 'govt schemes',
        'subsidy', 'subsidies', 'pm kisan', 'pmfby', 'kcc', 'kusum',
        'rythu bandhu', 'rythu bharosa', 'namo shetkari', 'yojana',
        'govt', 'government',
        // Hindi
        'सरकारी योजना', 'योजनाएं', 'सब्सिडी', 'पीएम किसान', 'सरकारी स्कीम', 'योजना',
        // Telugu
        'ప్రభుత్వ పథకాలు', 'పథకాలు', 'రైతు బంధు', 'రైతు భరోసా', 'సబ్సిడీ', 'పథకం',
        // Tamil
        'அரசு திட்டங்கள்', 'திட்டங்கள்', 'மானியம்', 'திட்டம்',
        // Kannada
        'ಸರ್ಕಾರಿ ಯೋಜನೆಗಳು', 'ಯೋಜನೆಗಳು', 'ಸಬ್ಸಿಡಿ', 'ಯೋಜನೆ',
        // Bengali
        'সরকারি প্রকল্প', 'ভর্তুকি', 'প্রকল্প',
        // Marathi
        'सरकारी योजना', 'अनुदान', 'योजना',
        // Gujarati
        'સરકારી યોજનાઓ', 'સબસિડી', 'યોજના',
        // Malayalam
        'സർക്കാർ പദ്ധതികൾ', 'സബ്‌സിഡി', 'പദ്ധതി',
        // Punjabi
        'ਸਰਕਾਰੀ ਸਕੀਮਾਂ', 'ਸਬਸਿਡੀ', 'ਸਕੀਮ',
        // Odia
        'ସରକାରୀ ଯୋଜନା', 'ସବସିଡି', 'ଯୋଜନା',
      ],
      labels: {
        'en': 'Government Schemes', 'hi': 'सरकारी योजनाएं',
        'te': 'ప్రభుత్వ పథకాలు', 'ta': 'அரசு திட்டங்கள்',
        'kn': 'ಸರ್ಕಾರಿ ಯೋಜನೆಗಳು', 'bn': 'সরকারি প্রকল্প',
        'mr': 'सरकारी योजना', 'gu': 'સરકારી યોજનાઓ',
        'ml': 'സർക്കാർ പദ്ധതികൾ', 'pa': 'ਸਰਕਾਰੀ ਯੋਜਨਾਵਾਂ',
        'or': 'ସରକାରୀ ଯୋଜନା',
      },
      builder: () => const SchemesScreen(),
    ),

    // 4. Crop Disease Detection & Leaf AI Scanner
    _CommandEntry(
      keywords: [
        'disease', 'crop disease', 'plant disease', 'leaf scan', 'leaf scanner',
        'detect disease', 'disease diagnosis', 'crop doctor', 'pest', 'fungus',
        'scan leaf', 'plant health',
        // Hindi
        'रोग', 'बीमारी', 'पत्ती स्कैन', 'फसल रोग', 'कीट', 'रोग पहचान',
        // Telugu
        'రోగం', 'వ్యాధి', 'ఆకు స్కానింగ్', 'పురుగుల మందు', 'చీడపీడలు', 'రోగ నిర్ధారణ',
        // Tamil
        'நோய்', 'இலை ஸ்கேன்', 'பயிர் நோய்', 'நோய் கண்டறிதல்',
        // Kannada
        'ರೋಗ', 'ಎಲೆ ಸ್ಕ್ಯಾನ್', 'ಬೆಳೆ ರೋಗ', 'ರೋಗ ಪತ್ತೆ',
        // Bengali
        'রোগ', 'পাতা স্ক্যান', 'ফসল রোগ',
        // Marathi
        'रोग', 'रोग ओळख', 'पान स्कॅन',
        // Gujarati
        'રોગ', 'રોગ ઓળખ', 'પાંદડું સ્કેન',
        // Malayalam
        'രോഗം', 'ഇല സ്കാൻ', 'വിള രോഗം',
        // Punjabi
        'ਰੋਗ', 'ਪੱਤੇ ਸਕੈਨ', 'ਫ਼ਸਲ ਰੋਗ',
        // Odia
        'ରୋଗ', 'ପତ୍ର ସ୍କାନ',
      ],
      labels: {
        'en': 'Disease Diagnosis', 'hi': 'रोग पहचान',
        'te': 'రోగ నిర్ధారణ', 'ta': 'நோய் கண்டறிதல்',
        'kn': 'ರೋಗ ಪತ್ತೆ', 'bn': 'রোগ নির্ণয়',
        'mr': 'रोग ओळख', 'gu': 'રોગ ઓળખ',
        'ml': 'രോഗ നിർണ്ണയം', 'pa': 'ਰੋਗ ਪਛਾਣ',
        'or': 'ରୋଗ ଚିହ୍ନଟ',
      },
      builder: () => const DiseaseScreen(),
    ),

    // 5. Market Prices & Live APMC Mandi Rates
    _CommandEntry(
      keywords: [
        'market', 'mandi', 'market price', 'market prices', 'mandi rates',
        'crop price', 'commodity price', 'crop rate', 'apmc', 'mandi bhav',
        // Hindi
        'बाजार', 'मंडी', 'बाजार भाव', 'फसल का भाव', 'दाम', 'मंडी भाव',
        // Telugu
        'మార్కెట్', 'మండి', 'ధరలు', 'మార్కెట్ ధరలు', 'సంత', 'పంట ధర',
        // Tamil
        'சந்தை', 'சந்தை விலைகள்', 'மண்டி', 'விலை',
        // Kannada
        'ಮಾರುಕಟ್ಟೆ', 'ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು', 'ಮಂಡಿ', 'ಬೆಲೆ',
        // Bengali
        'বাজার', 'বাজার দর', 'মন্ডি', 'দাম',
        // Marathi
        'बाजार', 'बाजारभाव', 'मंडी दर',
        // Gujarati
        'બજાર', 'બજાર ભાવ', 'મંડી',
        // Malayalam
        'വിപണി', 'വിപണി വിലകൾ', 'ചന്ത',
        // Punjabi
        'ਮੰਡੀ', 'ਭਾਅ', 'ਬਾਜ਼ਾਰ',
        // Odia
        'ବଜାର', 'ମଣ୍ଡି ଦର', 'ଦାମ',
      ],
      labels: {
        'en': 'Market Prices', 'hi': 'बाजार भाव',
        'te': 'మార్కెట్ ధరలు', 'ta': 'சந்தை விலைகள்',
        'kn': 'ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು', 'bn': 'বাজার দর',
        'mr': 'बाजारभाव', 'gu': 'બજાર ભાવ',
        'ml': 'വിപണി വിലകൾ', 'pa': 'ਮੰਡੀ ਭਾਅ',
        'or': 'ବଜାର ଦାମ',
      },
      builder: () => const MarketScreen(),
    ),

    // 6. Crop Advisor & Recommendation
    _CommandEntry(
      keywords: [
        'crop advisor', 'crop advisory', 'crop recommendation', 'suggest crop',
        'what to grow', 'what crop', 'crop guide', 'crop prediction',
        // Hindi
        'फसल सलाहकार', 'फसल सलाह', 'फसल सिफारिश', 'कौन सी फसल लगाएं',
        // Telugu
        'పంట సలహాదారు', 'పంట సిఫార్సు', 'పంట సలహా', 'ఏ పంట వేయాలి',
        // Tamil
        'பயிர் ஆலோசகர்', 'பயிர் பரிந்துரை',
        // Kannada
        'ಬೆಳೆ ಸಲಹೆಗಾರ', 'ಬೆಳೆ ಶಿಫಾರಸು', 'ಯಾವ ಬೆಳೆ',
        // Bengali
        'ফসল উপদেষ্টা', 'ফসল সুপারিশ',
        // Marathi
        'पीक सल्लागार', 'पीक शिफारस',
        // Gujarati
        'પાક સલાહકાર', 'પાક ભલામણ',
        // Malayalam
        'വിള ഉപദേശകൻ', 'വിള ശുപാർശ',
        // Punjabi
        'ਫਸਲ ਸਲਾਹਕਾਰ', 'ਫਸਲ ਸਿਫਾਰਸ਼',
        // Odia
        'ଫସଲ ପରାମର୍ଶ', 'ଫସଲ ସୁପାରିଶ',
      ],
      labels: {
        'en': 'Crop Advisor', 'hi': 'फसल सलाहकार',
        'te': 'పంట సలహాదారు', 'ta': 'பயிர் ஆலோசகர்',
        'kn': 'ಬೆಳೆ ಸಲಹೆಗಾರ', 'bn': 'ফসল উপদেষ্টা',
        'mr': 'पीक सल्लागार', 'gu': 'પાક સલાહકાર',
        'ml': 'വിള ഉപദേശകൻ', 'pa': 'ਫਸਲ ਸਲਾਹਕਾਰ',
        'or': 'ଫସଲ ପରାମର୍ଶଦାତା',
      },
      builder: () => const CropScreen(),
    ),

    // 7. Weather Alerts & Agro-Climate Radar
    _CommandEntry(
      keywords: [
        'weather', 'weather alert', 'weather alerts', 'weather forecast',
        'weather radar', 'climate', 'rain', 'rainfall', 'storm', 'frost',
        'risk alerts', 'urgent risk',
        // Hindi
        'मौसम', 'बारिश', 'मौसम अलर्ट', 'मौसम पूर्वानुमान', 'जोखिम', 'चेतावनी',
        // Telugu
        'వాతావరణం', 'వర్షం', 'వాతావరణ హెచ్చరికలు', 'హెచ్చరిక', 'తుఫాను',
        // Tamil
        'வானிலை', 'மழை', 'வானிலை எச்சரிக்கை', 'ஆபத்து',
        // Kannada
        'ಹವಾಮಾನ', 'ಮಳೆ', 'ಹವಾಮಾನ ಮುನ್ಸೂಚನೆ', 'ಅಪಾಯ',
        // Bengali
        'আবহাওয়া', 'বৃষ্টি', 'ঝুঁকি সতর্কতা',
        // Marathi
        'हवामान', 'पाऊस', 'हवामान अंदाज', 'धोका',
        // Gujarati
        'હવામાન', 'વરસાદ', 'જોખમ ચેતવણી',
        // Malayalam
        'കാലാവസ്ഥ', 'മഴ', 'അപകട മുന്നറിയിപ്പ്',
        // Punjabi
        'ਮੌਸਮ', 'ਮੀਂਹ', 'ਖ਼ਤਰਾ',
        // Odia
        'ପାଣିପାଗ', 'ବର୍ଷା', 'ବିପଦ ସତର୍କତା',
      ],
      labels: {
        'en': 'Weather & Risk Alerts', 'hi': 'मौसम और जोखिम अलर्ट',
        'te': 'వాతావరణ & ప్రమాద హెచ్చరికలు', 'ta': 'வானிலை & ஆபத்து எச்சரிக்கைகள்',
        'kn': 'ಹವಾಮಾನ & ಅಪಾಯ ಎಚ್ಚರಿಕೆಗಳು', 'bn': 'আবহাওয়া ও ঝুঁকি সতর্কতা',
        'mr': 'हवामान व धोका सूचना', 'gu': 'હવામાન અને જોખમ ચેતવણી',
        'ml': 'കാലാവസ്ഥ & അപകട മുന്നറിയിപ്പുകൾ', 'pa': 'ਮੌਸਮ ਅਤੇ ਖ਼ਤਰਾ ਅਲਰਟ',
        'or': 'ପାଣିପାଗ ଓ ବିପଦ ସତର୍କତା',
      },
      builder: () => const RiskAlertsScreen(),
    ),

    // 8. Machinery & Tractor Rental Services
    _CommandEntry(
      keywords: [
        'machinery', 'tractor', 'rent tractor', 'harvester', 'combine harvester',
        'drone', 'drone sprayer', 'equipment', 'farm machinery', 'rotavator',
        'power tiller',
        // Hindi
        'मशीनरी', 'ट्रैक्टर', 'किराए पर ट्रैक्टर', 'हार्वेस्टर', 'कृषि उपकरण',
        // Telugu
        'యంత్రాలు', 'ట్రాక్టర్', 'హార్వెస్టర్', 'డ్రోన్', 'యంత్ర పరికరాలు',
        // Tamil
        'டிராக்டர்', 'இயந்திரங்கள்', 'ஹார்வெஸ்டர்',
        // Kannada
        'ಯಂತ್ರೋಪಕರಣಗಳು', 'ಟ್ರಾಕ್ಟರ್', 'ಕೊಯ್ಲು ಯಂತ್ರ',
        // Bengali
        'মেশিনারি', 'ট্রাক্টর', 'যন্ত্রপাতি',
        // Marathi
        'यंत्रसामग्री', 'ट्रॅक्टर', 'अवजारे',
        // Gujarati
        'મશીનરી', 'ટ્રેક્ટર', 'ઓજારો',
        // Malayalam
        'ട്രാക്ടർ', 'യന്ത്രങ്ങൾ',
        // Punjabi
        'ਮਸ਼ੀਨਰੀ', 'ਟਰੈਕਟਰ',
        // Odia
        'ଟ୍ରାକ୍ଟର', 'ଯନ୍ତ୍ରପାତି',
      ],
      labels: {
        'en': 'Machinery Rental', 'hi': 'कृषि मशीनरी',
        'te': 'యంత్ర పరికరాలు', 'ta': 'விவசாய இயந்திரங்கள்',
        'kn': 'ಕೃಷಿ ಯಂತ್ರೋಪಕರಣಗಳು', 'bn': 'কৃষি যন্ত্রপাতি',
        'mr': 'कृषी यंत्रसामग्री', 'gu': 'કૃષિ મશીનરી',
        'ml': 'കാർഷിക യന്ത്രങ്ങൾ', 'pa': 'ਖੇਤੀ ਮਸ਼ੀਨਰੀ',
        'or': 'କୃଷି ଯନ୍ତ୍ରପାତି',
      },
      builder: () => const MachineryScreen(),
    ),

    // 9. Farm Labour & Workers Booking
    _CommandEntry(
      keywords: [
        'labour', 'labor', 'worker', 'workers', 'farm labour', 'hire labour',
        'coolie', 'mazdoor', 'labour booking',
        // Hindi
        'मजदूर', 'श्रमिक', 'मजदूरी', 'लेबर', 'मजदूर बुकिंग',
        // Telugu
        'కూలీ', 'కూలీలు', 'శ్రామికులు', 'పనివాళ్ళు', 'పనివారు',
        // Tamil
        'வேலையாட்கள்', 'கூலி', 'தொழிலாளர்கள்',
        // Kannada
        'ಕಾರ್ಮಿಕರು', 'ಕೂಲಿ', 'ಕೆಲಸಗಾರರು',
        // Bengali
        'শ্রমিক', 'মজুর',
        // Marathi
        'मजूर', 'कामगार',
        // Gujarati
        'મજૂર', 'શ્રમિક',
        // Malayalam
        'തൊഴിലാളികൾ', 'കൂലി',
        // Punjabi
        'ਮਜ਼ਦੂਰ', 'ਕਾਮੇ',
        // Odia
        'ଶ୍ରମିକ', 'ମୂଲିଆ',
      ],
      labels: {
        'en': 'Farm Labour Booking', 'hi': 'खेत मजदूर बुकिंग',
        'te': 'రైతు కూలీల బుకింగ్', 'ta': 'விவசாய தொழிலாளர்கள்',
        'kn': 'ಕೃಷಿ ಕಾರ್ಮಿಕರ ಬುಕಿಂಗ್', 'bn': 'কৃষি শ্রমিক বুকিং',
        'mr': 'शेतमजूर बुकिंग', 'gu': 'ખેત મજૂર બુકિંગ',
        'ml': 'തൊഴിലാളി ബുക്കിംഗ്', 'pa': 'ਖੇਤ ਮਜ਼ਦੂਰ ਬੁਕਿੰਗ',
        'or': 'କୃଷି ଶ୍ରମିକ ବୁକିଂ',
      },
      builder: () => const LabourScreen(),
    ),

    // 10. Yield & Profit Analytics
    _CommandEntry(
      keywords: [
        'yield', 'profit', 'yield profit', 'profit analytics', 'income',
        'earnings', 'roi', 'profit prediction', 'cost modeling',
        // Hindi
        'उपज', 'लाभ', 'मुनाफा', 'उपज और लाभ', 'कमाई', 'मुनाफा कैलकुलेटर',
        // Telugu
        'దిగుబడి', 'లాభం', 'దిగుబడి లాభం', 'ఆదాయం', 'లాభాల విశ్లేషణ',
        // Tamil
        'மகசூல்', 'லாபம்', 'வருமானம்', 'மகசூல் லாபம்',
        // Kannada
        'ಇಳುವರಿ', 'ಲಾಭ', 'ಆದಾಯ', 'ಇಳುವರಿ ಲಾಭ',
        // Bengali
        'ফলন', 'লাভ', 'মুনাফা',
        // Marathi
        'उत्पन्न', 'नफा', 'उत्पन्न व नफा',
        // Gujarati
        'ઉપજ', 'નફો', 'આવક',
        // Malayalam
        'വിളവ്', 'ലാഭം', 'വരുമാനം',
        // Punjabi
        'ਪੈਦਾਵਾਰ', 'ਮੁਨਾਫਾ', 'ਕਮਾਈ',
        // Odia
        'ଅମଳ', 'ଲାଭ', 'ଆୟ',
      ],
      labels: {
        'en': 'Yield & Profit', 'hi': 'उपज और लाभ',
        'te': 'దిగుబడి & లాభం', 'ta': 'மகசூல் & லாபம்',
        'kn': 'ಇಳುವರಿ & ಲಾಭ', 'bn': 'ফলন ও মুনাফা',
        'mr': 'उत्पन्न व नफा', 'gu': 'ઉપજ અને નફો',
        'ml': 'വിളവ് & ലാഭം', 'pa': 'ਪੈਦਾਵਾਰ ਅਤੇ ਮੁਨਾਫਾ',
        'or': 'ଅମଳ ଓ ଲାଭ',
      },
      builder: () => const YieldProfitScreen(),
    ),

    // 11. Fertilizer Calculator & Soil Management
    _CommandEntry(
      keywords: [
        'fertilizer', 'fertilizers', 'fertilizer calculator', 'urea', 'dap',
        'npk', 'soil health', 'manure', 'compost',
        // Hindi
        'उर्वरक', 'खाद', 'यूरिया', 'डीएपी', 'खाद कैलकुलेटर',
        // Telugu
        'ఎరువులు', 'ఎరువుల లెక్కింపు', 'యూరియా', 'డిఎపి', 'సేంద్రీయ ఎరువు',
        // Tamil
        'உரம்', 'உரக் கணக்கீடு', 'யூரியா',
        // Kannada
        'ಗೊಬ್ಬರ', 'ರಸಗೊಬ್ಬರ', 'ಯೂರಿಯಾ',
        // Bengali
        'সার', 'ইউরিয়া',
        // Marathi
        'खत', 'रासायनिक खत', 'युरिया',
        // Gujarati
        'ખાતર', 'યૂરિયા',
        // Malayalam
        'വളം', 'യൂറിയ',
        // Punjabi
        'ਖਾਦ', 'ਯੂਰੀਆ',
        // Odia
        'ସାର', 'ୟୁରିଆ',
      ],
      labels: {
        'en': 'Fertilizer Calculator', 'hi': 'उर्वरक कैलकुलेटर',
        'te': 'ఎరువుల లెక్కింపు', 'ta': 'உரக் கணக்கீடு',
        'kn': 'ಗೊಬ್ಬರ ಕ್ಯಾಲ್ಕುಲೇಟರ್', 'bn': 'সার ক্যালকুলেটর',
        'mr': 'खत कॅल्क्युलेटर', 'gu': 'ખાતર કેલ્ક્યુલેટર',
        'ml': 'വള കാൽക്കുലേറ്റർ', 'pa': 'ਖਾਦ ਕੈਲਕੁਲੇਟਰ',
        'or': 'ସାର କାଲକୁଲେଟର',
      },
      builder: () => const FertilizerScreen(),
    ),

    // 12. Crop Calendar & Seasonal Timetable
    _CommandEntry(
      keywords: [
        'crop calendar', 'calendar', 'sowing date', 'harvest time',
        'seasonal calendar', 'crop timetable',
        // Hindi
        'फसल कैलेंडर', 'कैलेंडर', 'बुवाई का समय',
        // Telugu
        'పంట క్యాలెండర్', 'క్యాలెండర్', 'విత్తే సమయం',
        // Tamil
        'பயிர் நாள்காட்டி', 'நாள்காட்டி',
        // Kannada
        'ಬೆಳೆ ಕ್ಯಾಲೆಂಡರ್', 'ಕ್ಯಾಲೆಂಡರ್',
        // Bengali
        'ফসল ক্যালেন্ডার',
        // Marathi
        'पीक कॅलेंडर',
        // Gujarati
        'પાક કૅલેન્ડર',
        // Malayalam
        'വിള കലണ്ടർ',
        // Punjabi
        'ਫਸਲ ਕੈਲੰਡਰ',
        // Odia
        'ଫସଲ କ୍ୟାଲେଣ୍ଡର',
      ],
      labels: {
        'en': 'Crop Calendar', 'hi': 'फसल कैलेंडर',
        'te': 'పంట క్యాలెండర్', 'ta': 'பயிர் நாள்காட்டி',
        'kn': 'ಬೆಳೆ ಕ್ಯಾಲೆಂಡರ್', 'bn': 'ফসল ক্যালেন্ডার',
        'mr': 'पीक कॅलेंडर', 'gu': 'પાક કૅલેન્ડર',
        'ml': 'വിള കലണ്ടർ', 'pa': 'ਫਸਲ ਕੈਲੰਡਰ',
        'or': 'ଫସଲ କ୍ୟାଲେଣ୍ଡର',
      },
      builder: () => const CropCalendarScreen(),
    ),

    // 13. Ask AgriNova / AI Assistant
    _CommandEntry(
      keywords: [
        'assistant', 'ai', 'ask', 'chat', 'ask agrinova', 'agrinova',
        'agronomist', 'ai chat', 'chat with ai',
        // Hindi
        'सहायक', 'सवाल', 'पूछें', 'एआई सहायक', 'अग्रिनोवा',
        // Telugu
        'అసిస్టెంట్', 'అడగండి', 'AI అసిస్టెంట్', 'అగ్రినోవా', 'సలహా',
        // Tamil
        'உதவியாளர்', 'கேள்வி', 'AI உதவியாளர்',
        // Kannada
        'ಸಹಾಯಕ', 'ಪ್ರಶ್ನೆ', 'AI ಸಹಾಯಕ',
        // Bengali
        'সহকারী', 'প্রশ্ন', 'AI সহকারী',
        // Marathi
        'सहाय्यक', 'प्रश्न', 'AI सहाय्यक',
        // Gujarati
        'સહાયક', 'પ્રશ્ન', 'AI સહાયક',
        // Malayalam
        'സഹായി', 'ചോദ്യം', 'AI സഹായി',
        // Punjabi
        'ਸਹਾਇਕ', 'ਸਵਾਲ', 'AI ਸਹਾਇਕ',
        // Odia
        'ସହାୟକ', 'ପ୍ରଶ୍ନ', 'AI ସହାୟକ',
      ],
      labels: {
        'en': 'Ask AgriNova AI', 'hi': 'अग्रिनोवा एआई सहायक',
        'te': 'అగ్రినోవా AI అసిస్టెంట్', 'ta': 'அக்ரிநோவா AI உதவியாளர்',
        'kn': 'ಅಗ್ರಿನೋವಾ AI ಸಹಾಯಕ', 'bn': 'অগ্রিনোভা AI সহকারী',
        'mr': 'अग्रिनोव्हा AI सहाय्यक', 'gu': 'અગ્રિનોવા AI સહાયક',
        'ml': 'അഗ്രിനോവ AI സഹായി', 'pa': 'ਐਗਰੀਨੋਵਾ AI ਸਹਾਇਕ',
        'or': 'ଅଗ୍ରିନୋଭା AI ସହାୟକ',
      },
      builder: () => const AIAssistantScreen(),
    ),

    // 14. Farmers Community Forum
    _CommandEntry(
      keywords: [
        'community', 'farmers community', 'forum', 'discussion', 'ask farmers',
        'farmer group',
        // Hindi
        'समुदाय', 'किसान समुदाय', 'चर्चा', 'किसान मंच',
        // Telugu
        'రైతుల సమాజం', 'రైతు వేదిక', 'కమ్యూనిటీ', 'రైతు సంఘం',
        // Tamil
        'விவசாய சமூகம்', 'சமூகம்', 'விவாதம்',
        // Kannada
        'ರೈತರ ಸಮುದಾಯ', 'ಸಮುದಾಯ', 'ಚರ್ಚೆ',
        // Bengali
        'কৃষক সম্প্রদায়', 'সম্প্রদায়',
        // Marathi
        'शेतकरी समुदाय', 'समुदाय', 'चर्चा मंच',
        // Gujarati
        'ખેડૂત સમુદાય', 'સમુદાય',
        // Malayalam
        'കർഷക സമൂഹം', 'സമൂഹം',
        // Punjabi
        'ਕਿਸਾਨ ਭਾਈਚਾਰਾ', 'ਭਾਈਚਾਰਾ',
        // Odia
        'ଚାଷୀ ସମୁଦାୟ', 'ସମୁଦାୟ',
      ],
      labels: {
        'en': 'Farmers Community', 'hi': 'किसान समुदाय',
        'te': 'రైతుల సమాజం', 'ta': 'விவசாய சமூகம்',
        'kn': 'ರೈತರ ಸಮುದಾಯ', 'bn': 'কৃষক সম্প্রদায়',
        'mr': 'शेतकरी समुदाय', 'gu': 'ખેડૂત સમુદાય',
        'ml': 'കർഷക സമൂഹം', 'pa': 'ਕਿਸਾਨ ਭਾਈਚਾਰਾ',
        'or': 'ଚାଷୀ ସମୁଦାୟ',
      },
      builder: () => const CommunityScreen(),
    ),

    // 15. Notifications & Alerts Center
    _CommandEntry(
      keywords: [
        'notifications', 'alerts', 'updates', 'messages', 'notice',
        'notification center', 'scheme alerts',
        // Hindi
        'सूचनाएं', 'अलर्ट', 'नोटिफिकेशन', 'संदेश',
        // Telugu
        'నోటిఫికేషన్లు', 'హెచ్చరికలు', 'సందేశాలు',
        // Tamil
        'அறிவிப்புகள்', 'எச்சரிக்கைகள்',
        // Kannada
        'ತಿಳುವಳಿಕೆಗಳು', 'ಸೂಚನೆಗಳು',
        // Bengali
        'বিজ্ঞপ্তি',
        // Marathi
        'सूचना', 'संदेश',
        // Gujarati
        'સૂચનાઓ',
        // Malayalam
        'അറിയിപ്പുകൾ',
        // Punjabi
        'ਨੋਟੀਫਿਕੇਸ਼ਨ',
        // Odia
        'ବିଜ୍ଞପ୍ତି',
      ],
      labels: {
        'en': 'Notifications & Alerts', 'hi': 'सूचनाएं और अलर्ट',
        'te': 'నోటిఫికేషన్లు & హెచ్చరికలు', 'ta': 'அறிவிப்புகள் & எச்சரிக்கைகள்',
        'kn': 'ತಿಳುವಳಿಕೆಗಳು & ಎಚ್ಚರಿಕೆಗಳು', 'bn': 'বিজ্ঞপ্তি ও সতর্কতা',
        'mr': 'सूचना व अलर्ट', 'gu': 'સૂચનાઓ અને ચેતવણી',
        'ml': 'അറിയിപ്പുകൾ', 'pa': 'ਨੋਟੀਫਿਕੇਸ਼ਨ ਅਤੇ ਅਲਰਟ',
        'or': 'ବିଜ୍ଞପ୍ତି ଓ ସତର୍କତା',
      },
      builder: () => const NotificationsScreen(),
    ),

    // 16. Farm Map & GPS Boundary Survey
    _CommandEntry(
      keywords: [
        'farm map', 'field map', 'land map', 'gps map', 'satellite map',
        'boundary', 'map',
        // Hindi
        'फार्म नक्शा', 'खेत का नक्शा', 'नक्शा',
        // Telugu
        'ఫార్మ్ మ్యాప్', 'పొలం మ్యాప్', 'మ్యాప్', 'భూమి మ్యాప్',
        // Tamil
        'பண்ணை வரைபடம்', 'வரைபடம்',
        // Kannada
        'ಫಾರ್ಮ್ ನಕ್ಷೆ', 'ಜಮೀನು ನಕ್ಷೆ', 'ನಕ್ಷೆ',
        // Bengali
        'ফার্ম মানচিত্র', 'মানচিত্র',
        // Marathi
        'शेत नकाशा', 'नकाशा',
        // Gujarati
        'ફાર્મ નકશો', 'નકશો',
        // Malayalam
        'ഫാം മാപ്പ്', 'മാപ്പ്',
        // Punjabi
        'ਫਾਰਮ ਨਕਸ਼ਾ', 'ਨਕਸ਼ਾ',
        // Odia
        'ଫାର୍ମ ମାନଚିତ୍ର', 'ମାନଚିତ୍ର',
      ],
      labels: {
        'en': 'Farm Map', 'hi': 'खेत का नक्शा',
        'te': 'ఫార్మ్ మ్యాప్', 'ta': 'பண்ணை வரைபடம்',
        'kn': 'ಜಮೀನು ನಕ್ಷೆ', 'bn': 'ফার্ম মানচিত্র',
        'mr': 'शेत नकाशा', 'gu': 'ફાર્મ નકશો',
        'ml': 'ഫാം മാപ്പ്', 'pa': 'ਫਾਰਮ ਨਕਸ਼ਾ',
        'or': 'ଫାର୍ମ ମାନଚିତ୍ର',
      },
      builder: () => const FarmMapScreen(),
    ),

    // 17. Specialized Farming Hub
    _CommandEntry(
      keywords: [
        'specialized farming', 'modern farming', 'advanced farming',
        'special farming', 'specialized agriculture',
        'विशिष्ट खेती', 'आधुनिक खेती', 'ప్రత్యేక వ్యవసాయం', 'ఆధునిక వ్యవసాయం',
        'சிறப்பு விவசாயம்', 'ವಿಶೇಷ ಕೃಷಿ', 'विशेष शेती',
      ],
      labels: {
        'en': 'Specialized Farming Hub', 'hi': 'विशिष्ट आधुनिक खेती',
        'te': 'ప్రత్యేక ఆధునిక వ్యవసాయం', 'ta': 'சிறப்பு நவீன விவசாயம்',
        'kn': 'ವಿಶೇಷ ಆಧುನಿಕ ಕೃಷಿ', 'bn': 'বিশেষ আধুনিক কৃষি',
        'mr': 'विशेष आधुनिक शेती', 'gu': 'વિશેષ આધુનિક ખેતી',
        'ml': 'പ്രത്യേക കൃഷി ഹബ്ബ്', 'pa': 'ਖਾਸ ਖੇਤੀਬਾੜੀ',
        'or': 'ବିଶେଷ କୃଷି କେନ୍ଦ୍ର',
      },
      builder: () => const SpecializedFarmingScreen(),
    ),

    // 18. Hydroponics Farming
    _CommandEntry(
      keywords: [
        'hydroponics', 'soilless farming', 'hydroponic',
        'हाइड्रोपोनिक्स', 'मिट्टी रहित खेती', 'హైడ్రోపోనిక్స్', 'మట్టిలేని సాగు',
        'ஹைட்ரோபோனிக்ஸ்', 'ಹೈಡ್ರೋಪೋನಿಕ್ಸ್',
      ],
      labels: {
        'en': 'Hydroponics Farming', 'hi': 'हाइड्रोपोनिक्स खेती',
        'te': 'హైడ్రోపోనిక్స్ సాగు', 'ta': 'ஹைட்ரோபோனிக்ஸ்',
        'kn': 'ಹೈಡ್ರೋಪೋನಿಕ್ಸ್ ಕೃಷಿ', 'bn': 'হাইড্রোপনিক্স',
        'mr': 'हायड्रोपोनिक्स शेती', 'gu': 'હાઇડ્રોપોનિક્સ',
        'ml': 'ഹൈഡ്രോപോണിക്സ്', 'pa': 'ਹਾਈਡ੍ਰੋਪੋਨਿਕਸ',
        'or': 'ହାଇଡ୍ରୋପୋନିକ୍ସ',
      },
      builder: () => const HydroponicsScreen(),
    ),

    // 19. Organic Farming
    _CommandEntry(
      keywords: [
        'organic farming', 'natural farming', 'organic', 'bio farming',
        'जैविक खेती', 'प्राकृतिक खेती', 'సేంద్రీయ వ్యవసాయం', 'ప్రకృతి వ్యవసాయం',
        'இயற்கை விவசாயம்', 'ಸಾವಯವ ಕೃಷಿ', 'জৈব কৃষি', 'सेंद्रिय शेती',
      ],
      labels: {
        'en': 'Organic Farming', 'hi': 'जैविक खेती',
        'te': 'సేంద్రీయ వ్యవసాయం', 'ta': 'இயற்கை விவசாயம்',
        'kn': 'ಸಾವಯವ ಕೃಷಿ', 'bn': 'জৈব কৃষি',
        'mr': 'सेंद्रिय शेती', 'gu': 'જૈવિક ખેતી',
        'ml': 'ജൈവകൃഷി', 'pa': 'ਜੈਵਿਕ ਖੇਤੀ',
        'or': 'ଜୈବିକ ଚାଷ',
      },
      builder: () => const OrganicHydroponicsScreen(),
    ),

    // 20. Poultry Farming
    _CommandEntry(
      keywords: [
        'poultry', 'chicken farm', 'poultry farm', 'broiler', 'egg farming',
        'पोल्ट्री', 'मुर्गी पालन', 'పౌల్ట్రీ', 'కోళ్ల పెంపకం',
        'கோழிப்பண்ணை', 'ಕೋಳಿ ಸಾಕಾಣಿಕೆ', 'হাঁস-মুরগি পালন',
      ],
      labels: {
        'en': 'Poultry Farming', 'hi': 'पोल्ट्री फार्मिंग',
        'te': 'పౌల్ట్రీ / కోళ్ల పెంపకం', 'ta': 'கோழிப்பண்ணை',
        'kn': 'ಕೋಳಿ ಸಾಕಾಣಿಕೆ', 'bn': 'পোল্ট্রি খামার',
        'mr': 'कुक्कुटपालन', 'gu': 'મરઘા પાલન',
        'ml': 'പൗൾട്രി ഫാം', 'pa': 'ਪੋਲਟਰੀ ਫਾਰਮਿੰਗ',
        'or': 'କୁକୁଡ଼ା ପାଳନ',
      },
      builder: () => const PoultryScreen(),
    ),

    // 21. Dairy & Livestock
    _CommandEntry(
      keywords: [
        'dairy', 'livestock', 'cattle', 'cow', 'dairy farming', 'buffalo',
        'milk yield', 'डेयरी', 'पशुपालन', 'गाय', 'డైరీ', 'పాడి పరిశ్రమ',
        'పశు సంవర్ధక', 'பால்பண்ணை', 'ಡೈರಿ', 'ಹೈನುಗಾರಿಕೆ',
      ],
      labels: {
        'en': 'Dairy & Livestock', 'hi': 'डेयरी व पशुपालन',
        'te': 'పాడి పరిశ్రమ & పశువులు', 'ta': 'பால்பண்ணை & கால்நடை',
        'kn': 'ಹೈನುಗಾರಿಕೆ & ಜಾನುವಾರು', 'bn': 'ডেইরি ও গবাদি পশু',
        'mr': 'दुग्धव्यवसाय व पशुपालन', 'gu': 'ડેરી અને પશુપાલન',
        'ml': 'ഡയറി & കന്നുകാലി', 'pa': 'ਡੇਅਰੀ ਅਤੇ ਪਸ਼ੂ ਪਾਲਣ',
        'or': 'ଡାଏରୀ ଓ ପଶୁପାଳନ',
      },
      builder: () => const DairyLivestockScreen(),
    ),

    // 22. Aquaculture / Fish Farming
    _CommandEntry(
      keywords: [
        'aquaculture', 'fish farming', 'fishery', 'prawn', 'shrimp',
        'मत्स्य पालन', 'मछली पालन', 'చేపల పెంపకం', 'రొయ్యల సాగు',
        'மீன் வளர்ப்பு', 'ಮೀನುಗಾರಿಕೆ', 'মৎস্য চাষ',
      ],
      labels: {
        'en': 'Aquaculture / Fish Farming', 'hi': 'मत्स्य पालन',
        'te': 'చేపలు & రొయ్యల సాగు', 'ta': 'மீன் வளர்ப்பு',
        'kn': 'ಮೀನು ಸಾಕಾಣಿಕೆ', 'bn': 'মৎস্য চাষ',
        'mr': 'मत्स्यशेती', 'gu': 'મત્સ્ય પાલન',
        'ml': 'മത്സ്യകൃഷി', 'pa': 'ਮੱਛੀ ਪਾਲਣ',
        'or': 'ମତ୍ସ୍ୟ ଚାଷ',
      },
      builder: () => const AquacultureScreen(),
    ),

    // 23. Horticulture & Orchards
    _CommandEntry(
      keywords: [
        'horticulture', 'orchard', 'fruit farming', 'vegetable garden',
        'बागवानी', 'फलों की खेती', 'ఉద్యానవనం', 'పండ్ల తోటలు',
        'தோட்டக்கலை', 'ತೋಟಗಾರಿಕೆ', 'উদ্যানপালন',
      ],
      labels: {
        'en': 'Horticulture & Orchards', 'hi': 'बागवानी और फल',
        'te': 'ఉద్యానవనం & పండ్ల తోటలు', 'ta': 'தோட்டக்கலை',
        'kn': 'ತೋಟಗಾರಿಕೆ', 'bn': 'উদ্যানপালন',
        'mr': 'बागकाम व फलोत्पादन', 'gu': 'બાગાયત',
        'ml': 'ഹോർട്ടികൾച്ചർ', 'pa': 'ਬਾਗਬਾਨੀ',
        'or': 'ଉଦ୍ୟାନ କୃଷି',
      },
      builder: () => const HorticultureScreen(),
    ),

    // 24. Farmer Profile & Account Settings
    _CommandEntry(
      keywords: [
        'profile', 'my profile', 'account', 'my details', 'farm details',
        'प्रोफाइल', 'मेरी प्रोफाइल', 'खाता', 'ప్రొఫైల్', 'నా ప్రొఫైల్',
        'சுயவிவரம்', 'ಪ್ರೊಫೈಲ್', 'প্রোফাইল',
      ],
      labels: {
        'en': 'My Profile', 'hi': 'मेरी प्रोफ़ाइल', 'te': 'నా ప్రొఫైల్',
        'ta': 'எனது சுயவிவரம்', 'kn': 'ನನ್ನ ಪ್ರೊಫೈಲ್', 'bn': 'আমার প্রোফাইল',
        'mr': 'माझी प्रोफाईल', 'gu': 'મારી પ્રોફાઈલ', 'ml': 'എന്റെ പ്രൊഫൈൽ',
        'pa': 'ਮੇਰੀ ਪ੍ਰੋਫਾਈਲ', 'or': 'ମୋ ପ୍ରୋଫାଇଲ',
      },
      builder: () => const ProfileScreen(),
    ),

    // 25. Contracts & Service Bookings
    _CommandEntry(
      keywords: [
        'contract', 'contracts', 'booking', 'bookings', 'my bookings',
        'service history', 'अनुबंध', 'बुकिंग', 'ఒప్పందాలు', 'బుకింగ్‌లు',
        'ஒப்பந்தங்கள்', 'ಗುತ್ತಿಗೆಗಳು', 'চুক্তি',
      ],
      labels: {
        'en': 'Contracts & Bookings', 'hi': 'अनुबंध और बुकिंग',
        'te': 'ఒప్పందాలు & బుకింగ్‌లు', 'ta': 'ஒப்பந்தங்கள் & முன்பதிவு',
        'kn': 'ಗುತ್ತಿಗೆ & ಬುಕಿಂಗ್', 'bn': 'চুক্তি ও বুকিং',
        'mr': 'करार व बुकिंग', 'gu': 'કરાર અને બુકિંગ',
        'ml': 'കരാർ & ബുക്കിംഗ്', 'pa': 'ਠੇਕੇ ਅਤੇ ਬੁਕਿੰਗ',
        'or': 'ଠିକା ଓ ବୁକିଂ',
      },
      builder: () => const ContractsScreen(),
    ),

    // 26. Disease Guide & Symptoms Gallery
    _CommandEntry(
      keywords: [
        'disease guide', 'gallery', 'symptoms', 'रोग गाइड', 'వ్యాధి గైడ్',
        'நோய் வழிகாட்டி', 'ರೋಗ ಮಾರ್ಗದರ್ಶಿ', 'রোগ গাইড',
      ],
      labels: {
        'en': 'Disease Guide', 'hi': 'रोग गाइड', 'te': 'వ్యాధి గైడ్',
        'ta': 'நோய் வழிகாட்டி', 'kn': 'ರೋಗ ಮಾರ್ಗದರ್ಶಿ', 'bn': 'রোগ গাইড',
        'mr': 'रोग मार्गदर्शक', 'gu': 'રોગ ગાઇડ', 'ml': 'രോഗ ഗൈഡ്',
        'pa': 'ਰੋਗ ਗਾਈਡ', 'or': 'ରୋଗ ଗାଇଡ୍',
      },
      builder: () => const DiseaseGalleryScreen(),
    ),

    // 27. Prediction History
    _CommandEntry(
      keywords: [
        'history', 'prediction history', 'past results',
        'इतिहास', 'చరిత్ర', 'வரலாறு', 'ಇತಿಹಾಸ', 'ইতিহাস',
      ],
      labels: {
        'en': 'Prediction History', 'hi': 'पूर्वानुमान इतिहास',
        'te': 'అంచనా చరిత్ర', 'ta': 'கணிப்பு வரலாறு',
        'kn': 'ಪೂರ್ವಾನುಮಾನ ಇತಿಹಾಸ', 'bn': 'ভবিষ্যদ্বাণী ইতিহাস',
        'mr': 'अंदाज इतिहास', 'gu': 'અંદાજ ઇતિહાસ', 'ml': 'പ്രവചന ചരിത്രം',
        'pa': 'ਅੰਦਾਜ਼ ਇਤਿਹਾਸ', 'or': 'ଅନୁମାନ ଇତିହାସ',
      },
      builder: () => const HistoryScreen(),
    ),

    // 28. Home Dashboard
    _CommandEntry(
      keywords: [
        'home', 'dashboard', 'main page', 'main screen',
        'होम', 'डैशबोर्ड', 'హోమ్', 'డ్యాష్‌బోర్డ్', 'ప్రధాన పేజీ',
        'முகப்பு', 'ಹೋಮ್', 'হোম', 'घर',
      ],
      labels: {
        'en': 'Home Dashboard', 'hi': 'होम डैशबोर्ड', 'te': 'హోమ్ డ్యాష్‌బోర్డ్',
        'ta': 'முகப்பு', 'kn': 'ಹೋಮ್', 'bn': 'হোম',
        'mr': 'होम', 'gu': 'હોમ', 'ml': 'ഹോം',
        'pa': 'ਹੋਮ', 'or': 'ହୋମ',
      },
      builder: () => const HomeScreen(),
      routeName: '/home',
    ),
  ];

  /// Strips conversational voice wrappers and filler phrases
  static String _cleanVoiceInput(String text) {
    String t = text.toLowerCase().trim();

    final conversationalPrefixes = [
      'hey agrinova', 'ok agrinova', 'agrinova',
      'can you please open', 'could you please open',
      'can you please show', 'could you please show',
      'can you open', 'could you open', 'can you show', 'could you show',
      'please open', 'please show', 'please take me to', 'please go to',
      'i want to see', 'i want to open', 'i want to go to',
      'take me to', 'navigate to', 'go to', 'open up', 'open',
      'show me', 'display', 'switch to', 'bring up', 'let us see', "let's see",
      'tell me about', 'look up', 'check out', 'check',
      // Hindi
      'कृपया खोलें', 'कृपया दिखाएं', 'मुझे दिखाओ', 'ले चलो', 'खोलो', 'खोलें',
      'दिखाइए', 'दिखाओ', 'जाओ', 'जाएं',
      // Telugu
      'దయచేసి చూపించు', 'దయచేసి తెరవండి', 'నాకు చూపించు', 'తీసుకెళ్ళు',
      'వెళ్ళు', 'తెరవండి', 'ఓపెన్ చెయ్యి', 'చూపించు',
      // Tamil
      'தயவுசெய்து திற', 'தயவுசெய்து காட்டு', 'திற', 'காட்டு', 'செல்',
      // Kannada
      'ದಯವಿಟ್ಟು ತೆರೆ', 'ದಯವಿಟ್ಟು ತೋರಿಸು', 'ತೆರೆ', 'ತೋರಿಸು', 'ಹೋಗು',
      // Bengali
      'দয়া করে খুলুন', 'খুলুন', 'দেখান',
      // Marathi
      'कृपया उघडा', 'उघडा', 'दाखवा',
      // Gujarati
      'કૃપા કરીને ખોલો', 'ખોલો', 'બતાવો',
    ];

    for (final prefix in conversationalPrefixes) {
      if (t.startsWith(prefix)) {
        t = t.substring(prefix.length).trim();
        break;
      }
    }

    return t;
  }

  /// Parse a voice command and return a matched result, or null if no match.
  static VoiceCommandResult? parseCommand(String text, String languageCode) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return null;

    final cleaned = _cleanVoiceInput(lower);

    // Sort commands with longer keywords first to match specific multi-word services
    final sortedCommands = List<_CommandEntry>.from(_commands)
      ..sort((a, b) {
        final aMax = a.keywords.map((k) => k.length).reduce((a, b) => a > b ? a : b);
        final bMax = b.keywords.map((k) => k.length).reduce((a, b) => a > b ? a : b);
        return bMax.compareTo(aMax);
      });

    // 1. Try matching against the cleaned text
    for (final cmd in sortedCommands) {
      for (final keyword in cmd.keywords) {
        final kwLower = keyword.toLowerCase();
        if (cleaned == kwLower ||
            cleaned.contains(kwLower) ||
            lower.contains(kwLower)) {
          final label = cmd.labels[languageCode] ?? cmd.labels['en']!;
          return VoiceCommandResult(
            screen: cmd.builder != null ? cmd.builder!() : null,
            routeName: cmd.routeName,
            screenLabel: label,
            isPop: cmd.isPop,
          );
        }
      }
    }

    // 2. Token-level matching for compound inputs
    final tokens = cleaned.split(RegExp(r'\s+'));
    for (final cmd in sortedCommands) {
      for (final keyword in cmd.keywords) {
        final kwLower = keyword.toLowerCase();
        if (tokens.contains(kwLower)) {
          final label = cmd.labels[languageCode] ?? cmd.labels['en']!;
          return VoiceCommandResult(
            screen: cmd.builder != null ? cmd.builder!() : null,
            routeName: cmd.routeName,
            screenLabel: label,
            isPop: cmd.isPop,
          );
        }
      }
    }

    return null;
  }

  /// Get an "already on screen" message in the profile language
  static String getAlreadyOnScreenMessage(String screenLabel, String languageCode) {
    final templates = {
      'en': 'You are already on $screenLabel screen',
      'hi': 'आप पहले से ही $screenLabel स्क्रीन पर हैं',
      'te': 'మీరు ఇప్పటికే $screenLabel స్క్రైన్ లో ఉన్నారు',
      'ta': 'நீங்கள் ஏற்கனவே $screenLabel திரையில் உள்ளீர்கள்',
      'kn': 'ನೀವು ಈಗಾಗಲೇ $screenLabel ಸ್ಕ್ರೀನ್ ನಲ್ಲಿದ್ದೀರಿ',
      'bn': 'আপনি ইতিমধ্যে $screenLabel স্ক্রিনে আছেন',
      'mr': 'तुम्ही आधीच $screenLabel स्क्रीनवर आहात',
      'gu': 'તમે પહેલેથી જ $screenLabel સ્ક્રીન પર છો',
      'ml': 'നിങ്ങൾ ഇതിനകം $screenLabel സ്ക്രീനിലാണ്',
      'pa': 'ਤੁਸੀਂ ਪਹਿਲਾਂ ਹੀ $screenLabel ਸਕ੍ਰੀਨ ਤੇ ਹੋ',
      'or': 'ଆପଣ ପୂର୍ବରୁ $screenLabel ସ୍କ୍ରିନରେ ଅଛନ୍ତି',
    };
    return templates[languageCode] ?? templates['en']!;
  }

  /// Get a "thinking/processing question" message in the profile language
  static String getThinkingMessage(String languageCode) {
    final templates = {
      'en': 'Processing your question...',
      'hi': 'आपके सवाल का जवाब खोज रहे हैं...',
      'te': 'మీ ప్రశ్నకు సమాధానం వెతుకుతున్నాము...',
      'ta': 'உங்கள் கேள்விக்கு பதில் தேடப்படுகிறது...',
      'kn': 'ನಿಮ್ಮ ಪ್ರಶ್ನೆಗೆ ಉತ್ತರ ಹುಡುಕುತ್ತಿದ್ದೇವೆ...',
      'bn': 'আপনার প্রশ্নের উত্তর খোঁজা হচ্ছে...',
      'mr': 'तुमच्या प्रश्नाचे उत्तर शोधत आहोत...',
      'gu': 'તમારા પ્રશ્નનો જવાબ શોધી રહ્યા છીએ...',
      'ml': 'നിങ്ങളുടെ ചോദ്യത്തിന് ഉത്തരം കണ്ടെത്തുന്നു...',
      'pa': 'ਤੁਹਾਡੇ ਸਵਾਲ ਦਾ ਜਵਾਬ ਲੱਭ ਰਹੇ ਹਾਂ...',
      'or': 'ଆପଣଙ୍କ ପ୍ରଶ୍ନର ଉତ୍ତର ଖୋଜାଯାଉଛି...',
    };
    return templates[languageCode] ?? templates['en']!;
  }

  /// Get a "going back" message in the profile language
  static String getGoingBackMessage(String languageCode) {
    final templates = {
      'en': 'Going back',
      'hi': 'वापस जा रहे हैं',
      'te': 'వెనక్కి వెళ్తున్నాము',
      'ta': 'பின்னால் செல்கிறோம்',
      'kn': 'ಹಿಂದೆ ಹೋಗುತ್ತಿದ್ದೇವೆ',
      'bn': 'ফিরে যাচ্ছি',
      'mr': 'मागे जात आहोत',
      'gu': 'પાછા જઈ રહ્યા છીએ',
      'ml': 'പുറകോട്ട് പോകുന്നു',
      'pa': 'ਵਾਪਸ ਜਾ ਰਹੇ ਹਾਂ',
      'or': 'ପଛକୁ ଫେରୁଛୁ',
    };
    return templates[languageCode] ?? templates['en']!;
  }

  /// Get a "navigating to" message in the profile language
  static String getNavigatingMessage(String screenLabel, String languageCode) {
    final templates = {
      'en': 'Opening $screenLabel',
      'hi': '$screenLabel खोल रहे हैं',
      'te': '$screenLabel తెరుస్తున్నాము',
      'ta': '$screenLabel திறக்கிறோம்',
      'kn': '$screenLabel ತೆರೆಯುತ್ತಿದ್ದೇವೆ',
      'bn': '$screenLabel খোলা হচ্ছে',
      'mr': '$screenLabel उघडत आहे',
      'gu': '$screenLabel ખોલી રહ્યા છીએ',
      'ml': '$screenLabel തുറക്കുന്നു',
      'pa': '$screenLabel ਖੋਲ ਰਹੇ ਹਾਂ',
      'or': '$screenLabel ଖୋଲୁଛୁ',
    };
    return templates[languageCode] ?? templates['en']!;
  }

  /// Get a "didn't understand" message in the profile language
  static String getNotUnderstoodMessage(String languageCode) {
    final messages = {
      'en': 'Sorry, I didn\'t understand. Please try again.',
      'hi': 'समझ नहीं आया। कृपया फिर से बोलें।',
      'te': 'అర్థం కాలేదు. దయచేసి మళ్ళీ చెప్పండి.',
      'ta': 'புரியவில்லை. தயவுசெய்து மீண்டும் சொல்லுங்கள்.',
      'kn': 'ಅರ್ಥವಾಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಹೇಳಿ.',
      'bn': 'বুঝতে পারিনি। অনুগ্রহ করে আবার বলুন।',
      'mr': 'समजले नाही. कृपया पुन्हा सांगा.',
      'gu': 'સમજ ન આવ્યું. કૃપા કરીને ફરી કહો.',
      'ml': 'മനസ്സിലായില്ല. ദയവായി വീണ്ടും പറയൂ.',
      'pa': 'ਸਮਝ ਨਹੀਂ ਆਇਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਬੋਲੋ।',
      'or': 'ବୁଝିପାରିଲି ନାହିଁ। ଦୟାକରି ପୁନର୍ବାର କୁହନ୍ତୁ।',
    };
    return messages[languageCode] ?? messages['en']!;
  }

  /// Get a "listening" message in the profile language
  static String getListeningMessage(String languageCode) {
    final messages = {
      'en': 'Listening for service command...',
      'hi': 'सेवा कमांड सुन रहे हैं...',
      'te': 'సర్వీస్ కమాండ్ వింటున్నాము...',
      'ta': 'சேவை கட்டளையைக் கேட்கிறோம்...',
      'kn': 'ಸೇವೆ ಆಜ್ಞೆಯನ್ನು ಕೇಳುತ್ತಿದ್ದೇವೆ...',
      'bn': 'সেবা কমান্ড শুনছি...',
      'mr': 'सेवा आज्ञा ऐकत आहोत...',
      'gu': 'સેવા આદેશ સાંભળી રહ્યા છીએ...',
      'ml': 'സേവന കമാൻഡ് കേൾക്കുന്നു...',
      'pa': 'ਸੇਵਾ ਕਮਾਂਡ ਸੁਣ ਰਹੇ ਹਾਂ...',
      'or': 'ସେବା କମାଣ୍ଡ ଶୁଣୁଛୁ...',
    };
    return messages[languageCode] ?? messages['en']!;
  }
}

class _CommandEntry {
  final List<String> keywords;
  final Map<String, String> labels;
  final Widget Function()? builder;
  final String? routeName;
  final bool isPop;

  _CommandEntry({
    required this.keywords,
    required this.labels,
    this.builder,
    this.routeName,
    this.isPop = false,
  });
}
