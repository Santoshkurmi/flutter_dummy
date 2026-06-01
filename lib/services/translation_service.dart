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

    // Account Details page
    'My Accounts': 'मेरा खाताहरू',
    'All': 'सबै',
    'Savings': 'बचत',
    'Loans': 'ऋण',
    'Share Capital': 'सेयर पुँजी',
    'Savings Accounts': 'बचत खाताहरू',
    'Loan Accounts': 'ऋण खाताहरू',
    'Share Capital Accounts': 'सेयर पुँजी खाताहरू',
    'No accounts found in this category.': 'यस श्रेणीमा कुनै खाता भेटिएन।',
    'Something went wrong': 'केही गलत भयो',
    'Failed to retrieve your cooperative accounts. Please go back and try opening the page again.': 'तपाईंको सहकारी खाताहरू प्राप्त गर्न असफल भयो। कृपया पछाडि जानुहोस् र पृष्ठ फेरि खोल्ने प्रयास गर्नुहोस्।',

    // Account Single Details page
    'Quick Actions': 'द्रुत कार्यहरू',
    'Account Information': 'खाता जानकारी',
    'Payment': 'भुक्तानी',
    'Rate Logs': 'ब्याज दर लगहरू',
    'Schedules': 'तालिका',

    // Account detail field labels
    'Interest Rate': 'ब्याज दर',
    'Accrued Interest': 'संचित ब्याज',
    'Minimum Balance': 'न्यूनतम ब्यालेन्स',
    'Opened Date (BS)': 'खाता खोलिएको मिति (वि.सं.)',
    'Maturity Date': 'परिपक्वता मिति',
    'Interest Posting Date': 'ब्याज पोस्टिङ मिति',
    'Maturity Date (BS)': 'परिपक्वता मिति (वि.सं.)',
    'Principal Matured': 'परिपक्व मूलधन',
    'Due Interest': 'बाँकी ब्याज',
    'Fine Amount': 'जरिवाना रकम',
    'Total Matured to Pay': 'कुल तिर्नुपर्ने रकम',
    'Share Capital Value': 'सेयर पुँजी मूल्य',
    'Total Share Units': 'कुल सेयर इकाइ',
    'Member Status': 'सदस्य स्थिति',
    'Active Shareholder': 'सक्रिय सेयरधारक',
    'Units': 'इकाइ',

    // Account Ledger page
    'Account Statement': 'खाता विवरण',
    'TRANSACTION HISTORY': 'कारोबार इतिहास',
    'Custom Date Range (BS)': 'कस्टम मिति दायरा (वि.सं.)',
    'From Date': 'देखि मिति',
    'To Date': 'सम्म मिति',
    'Apply Filter': 'फिल्टर लागू गर्नुहोस्',
    'Filter': 'फिल्टर',
    'Filter Active': 'फिल्टर सक्रिय',
    '7 Days': '७ दिन',
    '15 Days': '१५ दिन',
    '1 Month': '१ महिना',
    'Showing last 20': 'अन्तिम २० देखाइँदै',
    'Last 7 Days': 'अन्तिम ७ दिन',
    'Last 15 Days': 'अन्तिम १५ दिन',
    'Last Month': 'गत महिना',
    'Filtered Range': 'फिल्टर गरिएको दायरा',
    'No transactions found.': 'कुनै कारोबार भेटिएन।',
    'Try broadening your filter parameters.': 'आफ्नो फिल्टर मापदण्ड फराकिलो पार्ने प्रयास गर्नुहोस्।',
    'This account has no recent activity.': 'यस खातामा भर्खरको कुनै गतिविधि छैन।',
    'Download PDF': 'PDF डाउनलोड गर्नुहोस्',
    'Print': 'प्रिन्ट',

    // Settings page
    'Receive real-time transaction updates and alerts': 'वास्तविक-समय कारोबार अपडेट र अलर्टहरू प्राप्त गर्नुहोस्',
    'Backup copy of standard messages over cellular connection': 'सेलुलर जडानमा मानक सन्देशहरूको ब्याकअप प्रतिलिपि',
    'Unlock account and authorise using hardware fingerprint': 'हार्डवेयर फिंगरप्रिन्ट प्रयोग गरी खाता खोल्नुहोस् र अधिकृत गर्नुहोस्',
    'Configure absolute limits allowed for mobile banking services': 'मोबाइल बैंकिङ सेवाहरूका लागि अनुमति दिइएको सीमा कन्फिगर गर्नुहोस्',
    'Reset Application Settings': 'एप सेटिङ रिसेट गर्नुहोस्',
    'Reset Settings?': 'सेटिङ रिसेट गर्ने?',
    'This will revert all customization preferences, switches, limits, and authentication profiles to default state.': 'यसले सबै अनुकूलन प्राथमिकताहरू, स्विचहरू, सीमाहरू र प्रमाणीकरण प्रोफाइलहरू पूर्वनिर्धारित अवस्थामा फर्काउनेछ।',
    'Reset': 'रिसेट',
    'Configure alerts, daily limits and fingerprint setup': 'अलर्ट, दैनिक सीमा र फिंगरप्रिन्ट सेटअप कन्फिगर गर्नुहोस्',
    'Become a member by filling self-registration wizard': 'स्वयं-दर्ता विजार्ड भरेर सदस्य बन्नुहोस्',
    'Generate and download custom cooperative QR codes': 'कस्टम सहकारी QR कोडहरू उत्पन्न र डाउनलोड गर्नुहोस्',
    'View Bikram Sambat dates, Nepalese holidays and board runs': 'विक्रम सम्बत मितिहरू, नेपाली बिदाहरू र बोर्ड रनहरू हेर्नुहोस्',
    'Technical details, architecture and specs by Bright Software': 'ब्राइट सफ्टवेयरद्वारा प्राविधिक विवरण, आर्किटेक्चर र स्पेसिफिकेसनहरू',
    'QR Generator': 'QR जेनेरेटर',

    // Home tab
    'Namaste, 🙏': 'नमस्ते, 🙏',
    'Account Summary': 'खाता सारांश',
    'No recent transactions found.': 'भर्खरका कुनै कारोबार भेटिएन।',
    'Connection Failed': 'जडान असफल',
    'We had trouble communicating with the cooperative servers. Please check your internet connection.': 'सहकारी सर्भरहरूसँग सञ्चार गर्न समस्या भयो। कृपया आफ्नो इन्टरनेट जडान जाँच गर्नुहोस्।',
    'Try Again': 'फेरि प्रयास गर्नुहोस्',

    // Quick action labels (home tab)
    'Pay': 'भुक्तानी',
    'Internet': 'इन्टरनेट',
    'Electricity': 'विद्युत',
    'TopUp': 'टपअप',
    'Recharge': 'रिचार्ज',
    'Accounts': 'खाताहरू',
    'Member Register': 'सदस्य दर्ता',

    // Interest Rate Logs
    'Interest Rate Logs': 'ब्याज दर लगहरू',
    'Ongoing': 'चालू',
    'Before': 'अघि',
    'From': 'देखि',
    'To': 'सम्म',
    'Rate': 'दर',
    'entries': 'प्रविष्टिहरू',
    'No rate change history found.': 'ब्याज दर परिवर्तनको इतिहास फेला परेन।',
    'The current rate has been applied since the beginning.': 'सुरुदेखि नै हालको दर लागू गरिएको छ।',
    'Applied Date': 'लागू मिति',
    'Number of Days': 'दिन संख्या',

    // Loan Schedules
    'Loan Payment Schedules': 'ऋण भुक्तानी तालिका',
    'Payment Date': 'भुक्तानी मिति',
    'Installment': 'किस्ता',
    'Interest': 'ब्याज',
    'Paid Installment': 'तिरेको किस्ता',
    'No schedules found.': 'भुक्तानी तालिका फेला परेन।',
    'installments': 'किस्ताहरू',
    'Show Interest Schedule': 'ब्याज तालिका देखाउनुहोस्',
    'Days': 'दिन',
    'Days Passed': 'नाघेको दिन',
    'S.N.': 'क्र.सं.',
    'Installment Amount': 'किस्ता रकम',
    'Paid Principal': 'तिरेको साँवा',
    'Interest Amount': 'ब्याज रकम',
    'Paid': 'तिरेको',
    'Overdue': 'भाखा नाघेको',
    'Upcoming': 'आगामी',
    'Period': 'अवधि',
    'To: ': 'सम्म: ',
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
