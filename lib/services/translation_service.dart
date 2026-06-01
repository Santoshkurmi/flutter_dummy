import '../store/auth_store.dart';

class TranslationService {
  static final Map<String, String> _nepaliTranslations = {
    // Shared / Buttons
    'Get Started': 'सुरु गरौं',
    'Skip': 'छोड्नुहोस्',
    'Cancel': 'रद्द गर्नुहोस्',
    'Submit': 'बुझाउनुहोस्',
    'Next': 'अर्को',
    'Back': 'पछाडि',
    'Continue': 'जारी राख्नुहोस्',
    'Save': 'बचत गर्नुहोस्',
    'Confirm': 'पुष्टि गर्नुहोस्',
    'Logout': 'बाहिरिनुहोस्',
    'Verify': 'प्रमाणित गर्नुहोस्',
    'Search': 'खोज्नुहोस्',
    'Close': 'बन्द गर्नुहोस्',

    // Onboarding
    'Smart Banking': 'स्मार्ट बैंकिङ्ग',
    'Manage your wealth with intelligence': 'आफ्नो सम्पत्ति बुद्धिमानीपूर्वक व्यवस्थापन गर्नुहोस्',
    'Bright Bank brings you a premium, intuitive way to track your savings and manage transactions instantly.': 'ब्राइट बैंकले तपाईंलाई आफ्नो बचत ट्र्याक गर्न र तत्काल लेनदेनहरू व्यवस्थित गर्न एक प्रिमियम, सहज तरिका प्रदान गर्दछ।',
    'Ironclad Security': 'अभेद्य सुरक्षा',
    'Your safety is our priority': 'तपाईंको सुरक्षा हाम्रो प्राथमिकता हो',
    'With multi-factor authentication and device-level encryption, your funds are safer than ever before.': 'बहु-कारक प्रमाणीकरण र उपकरण-स्तर ईन्क्रिप्शनको साथ, तपाईंको कोष पहिले भन्दा धैरे सुरक्षित छ।',
    'Instant Power': 'तत्काल शक्ति',
    'Banking at the speed of life': 'जीवनको गतिमा बैंकिङ्ग',
    'Transfer money, pay bills, and get real-time alerts. Experience the fastest banking app in Nepal.': 'पैसा पठाउनुहोस्, बिलहरू तिर्नुहोस्, र वास्तविक-समय अलर्टहरू प्राप्त गर्नुहोस्। नेपालकै सबैभन्दा छिटो बैंकिङ्ग एपको अनुभव गर्नुहोस्।',

    // Setup Preferences
    'App Preferences': 'एप प्राथमिकताहरू',
    'Choose Language': 'भाषा छान्नुहोस्',
    'Choose Theme': 'थिम छान्नुहोस्',
    'Light Mode': 'उज्यालो मोड',
    'Dark Mode': 'अँध्यारो मोड',
    'Select English or Nepali language': 'अंग्रेजी वा नेपाली भाषा चयन गर्नुहोस्',
    'Select your default visual theme style': 'तपाईंको पूर्वनिर्धारित थिम चयन गर्नुहोस्',
    'Proceed to Select Cooperative': 'सहकारी चयन गर्न अगाडि बढ्नुहोस्',
    'Proceed to Mobile Banking': 'बैंकिङ्ग सेवामा जानुहोस्',
    'Customize Experience': 'अनुभव अनुकूलित गर्नुहोस्',
    'Set your preferred language and layout theme style': 'आफ्नो मनपर्ने भाषा र थिम चयन गर्नुहोस्',

    // Cooperative selection
    'Select Cooperative': 'सहकारी चयन गर्नुहोस्',
    'Choose your cooperative to proceed': 'अगाडि बढ्नको लागि आफ्नो सहकारी रोज्नुहोस्',
    'Search Cooperative...': 'सहकारी खोज्नुहोस्...',
    'Enter custom URL gateway...': 'कस्टम URL गेटवे प्रविष्ट गर्नुहोस्...',

    // Status check
    'Mobile Banking Verification': 'मोबाइल बैंकिङ्ग प्रमाणीकरण',
    'Verify Registered Mobile Number': 'दर्ता गरिएको मोबाइल नम्बर प्रमाणित गर्नुहोस्',
    'Enter Mobile Number': 'मोबाइल नम्बर प्रविष्ट गर्नुहोस्',
    'VERIFY STATUS': 'स्थिति प्रमाणित गर्नुहोस्',
    'We will check your registration status and guide you to the next step.': 'हामी तपाईंको दर्ता स्थिति जाँच गर्नेछौं र अर्को चरणमा मार्गदर्शन गर्नेछौं।',

    // Login
    'Enter Password': 'पासवर्ड प्रविष्ट गर्नुहोस्',
    'Enter your login password or MPIN': 'तपाईंको लगइन पासवर्ड वा MPIN प्रविष्ट गर्नुहोस्',
    'Tap to Login with Fingerprint': 'औंठाछापद्वारा लगइन गर्न ट्याप गर्नुहोस्',
    'Tap to Login with Face ID': 'फेस आईडीद्वारा लगइन गर्न ट्याप गर्नुहोस्',
    'LOGIN': 'लगइन',

    // Dashboard
    'Bright Savings Account': 'ब्राइट बचत खाता',
    'TOTAL ACCOUNT BALANCE': 'कुल खाता ब्यालेन्स',
    'LOAN BALANCE': 'ऋण ब्यालेन्स',
    'SHARE CAPITAL': 'सेयर पुँजी',
    'QUICK ACTIONS': 'द्रुत सेवाहरू',
    'RECENT TRANSACTIONS': 'भर्खरका कारोबारहरू',
    'All Services': 'सबै सेवाहरू',
    'Send Money': 'पैसा पठाउनुहोस्',
    'Receive': 'प्राप्त गर्नुहोस्',
    'Statement': 'विवरण',
    'Deposit': 'जम्मा',
    'Ledger': 'खातापाता',
    'Share': 'सेयर',
    'Loan': 'ऋण',
    'Calendar': 'पात्रो',
    'Utility': 'उपयोगिता',
    'Notice': 'सूचना',
    'Calculator': 'कैलकुलेटर',
    'Self Register': 'स्वयं दर्ता',
    'History': 'इतिहास',
    'Transfer': 'स्थानान्तरण',
    'Growth': 'वृद्धि',
    'Security': 'सुरक्षा',
    'Rewards': 'पुरस्कार',
    'Remittance': 'विप्रेषण',
    'Scan QR': 'क्युआर स्क्यान',
    'Support': 'सहायता',

    // Profile
    'COOPERATIVE IDENTITY': 'सहकारी पहिचान',
    'Cooperative Bank': 'सहकारी बैंक',
    'UTILITY SERVICES & PREFERENCES': 'उपयोगिता सेवाहरू र प्राथमिकताहरू',
    'Self Registration': 'स्वयं दर्ता',
    'Nepali Calendar BS 2083': 'नेपाली पात्रो वि.सं. २०८३',
    'About Developer': 'डेभलपरको बारेमा',
    'Logout Account': 'खाता बाहिरिनुहोस्',

    // Bottom navigation tabs
    'Home': 'गृहपृष्ठ',
    'Payments': 'भुक्तानी',
    'Alerts': 'सूचनाहरू',
    'Profile': 'प्रोफाइल',

    // Theme labels
    'Light': 'उज्यालो',
    'Dark': 'अँध्यारो',
    'System': 'प्रणाली',
    'Theme': 'थिम',

    // Settings page
    'Settings': 'सेटिङ्स',
    'NOTIFICATIONS': 'सूचनाहरू',
    'Push Notifications': 'पुश सूचनाहरू',
    'SMS Alerts': 'एसएमएस अलर्ट',
    'SECURITY': 'सुरक्षा',
    'Biometric Login': 'बायोमेट्रिक लगइन',
    'TRANSACTION LIMITS': 'कारोबार सीमा',
    'Daily Transfer Limit': 'दैनिक स्थानान्तरण सीमा',
    'APPEARANCE': 'देखावट',
    'View All': 'सबै हेर्नुहोस्',
    'Show More': 'थप हेर्नुहोस्',

    // QR Scanner
    'No QR code or barcode found in the image.': 'तस्बिरमा QR कोड वा बारकोड फेला परेन।',
    'Scan Result': 'स्क्यान परिणाम',
    'Scan Again': 'फेरि स्क्यान गर्नुहोस्',
    'Copy': 'कपी गर्नुहोस्',
    'Platform Not Supported': 'प्लेटफर्म समर्थित छैन',
    'QR Scanning is only available on iOS and Android devices. Please open this app on a supported mobile device to scan QR codes.': 'क्युआर स्क्यान आईओएस र एन्ड्रोइड उपकरणहरूमा मात्र उपलब्ध छ। क्युआर कोड स्क्यान गर्न कृपया यो एप समर्थित मोबाइल उपकरणमा खोल्नुहोस्।',
    'DEVICE COMPATIBILITY': 'उपकरण अनुकूलता',
    'Web & Desktop Platforms': 'वेब र डेस्कटप प्लेटफर्महरू',
    'Supported': 'समर्थित',
    'Not Supported': 'समर्थित छैन',

    // New member
    'New to Sahakari?': 'ब्राइट सहकारीमा नयाँ?',
    'Register New Member': 'नयाँ सदस्य दर्ता',
  };

  static String translate(String key) {
    final language = AuthStore().language;
    if (language == 'ne') {
      return _nepaliTranslations[key] ?? key;
    }
    return key;
  }

  static String toNepaliNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const nepali = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    String result = input;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], nepali[i]);
    }
    return result;
  }
}

extension TranslationExtension on String {
  String get tr => TranslationService.translate(this);
  String get trd {
    final language = AuthStore().language;
    if (language == 'ne') {
      return TranslationService.toNepaliNumbers(this);
    }
    return this;
  }
}

extension NumTranslationExtension on num {
  String get trd {
    final language = AuthStore().language;
    final formatted = toString();
    if (language == 'ne') {
      return TranslationService.toNepaliNumbers(formatted);
    }
    return formatted;
  }
}
