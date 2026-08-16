import 'quran_language.dart';

/// UI copy that follows the same language the user picked for the Quran
/// translation (QuranLanguageController) — currently wired up for the
/// Profile and Language screens, more screens can move onto this as they're
/// done.
///
/// Adding a language later is exactly one step: add an entry to every key
/// below (and to `supportedQuranLanguages` in quran_language.dart if it
/// should also appear in the picker). Nothing else in the app needs to
/// change — every call site already just asks for a key and gets back
/// whatever the current language has for it, falling back to English so a
/// language that's only partially translated never shows a blank string
/// instead of a key typo.
///
/// Deliberately NOT Flutter's built-in Locale/ARB localization system: that
/// ties into MaterialApp's locale and affects the whole app at once, where
/// this app instead already drives light/dark, the feed background and the
/// Quran language from small standalone controllers. This matches that
/// pattern instead of introducing a second, incompatible one.
class AppStrings {
  const AppStrings._();

  static const Map<String, Map<String, String>> _strings = {
    'profile_title': {
      'en': 'Profile',
      'tr': 'Profil',
      'ar': 'الملف الشخصي',
      'de': 'Profil',
      'fr': 'Profil',
      'es': 'Perfil',
      'ur': 'پروفائل',
      'id': 'Profil',
    },

    'unlock_title': {
      'en': 'Unlock everything',
      'tr': 'Her şeyin kilidini aç',
      'ar': 'افتح كل شيء',
      'de': 'Alles freischalten',
      'fr': 'Tout débloquer',
      'es': 'Desbloquear todo',
      'ur': 'سب کچھ ان لاک کریں',
      'id': 'Buka semuanya',
    },
    'unlock_subtitle': {
      'en': 'All quotes, themes,\ncategories & no ads',
      'tr': 'Tüm alıntılar, temalar,\nkategoriler & reklamsız',
      'ar': 'جميع الاقتباسات والسمات\nوالفئات وبدون إعلانات',
      'de': 'Alle Zitate, Themes,\nKategorien & keine Werbung',
      'fr': 'Toutes les citations, thèmes,\ncatégories & sans publicité',
      'es': 'Todas las citas, temas,\ncategorías y sin anuncios',
      'ur': 'تمام اقتباسات، تھیمز،\nزمرے اور بغیر اشتہار کے',
      'id': 'Semua kutipan, tema,\nkategori & tanpa iklan',
    },

    'quick_actions': {
      'en': 'Quick actions',
      'tr': 'Hızlı işlemler',
      'ar': 'إجراءات سريعة',
      'de': 'Schnellzugriff',
      'fr': 'Actions rapides',
      'es': 'Acciones rápidas',
      'ur': 'فوری اقدامات',
      'id': 'Aksi cepat',
    },
    'topics_you_follow': {
      'en': 'Topics you\nfollow',
      'tr': 'Takip ettiğin\nkonular',
      'ar': 'المواضيع التي\nتتابعها',
      'de': 'Themen, denen\ndu folgst',
      'fr': 'Sujets\nsuivis',
      'es': 'Temas que\nsigues',
      'ur': 'وہ موضوعات جن کی\nآپ پیروی کرتے ہیں',
      'id': 'Topik yang\nkamu ikuti',
    },
    'app_icon': {
      'en': 'App icon',
      'tr': 'Uygulama simgesi',
      'ar': 'أيقونة التطبيق',
      'de': 'App-Symbol',
      'fr': "Icône de l'app",
      'es': 'Icono de la app',
      'ur': 'ایپ آئیکن',
      'id': 'Ikon aplikasi',
    },
    'reminders': {
      'en': 'Reminders',
      'tr': 'Hatırlatıcılar',
      'ar': 'التذكيرات',
      'de': 'Erinnerungen',
      'fr': 'Rappels',
      'es': 'Recordatorios',
      'ur': 'یاد دہانیاں',
      'id': 'Pengingat',
    },
    'widgets': {
      'en': 'Widgets',
      'tr': 'Widget\'lar',
      'ar': 'الودجات',
      'de': 'Widgets',
      'fr': 'Widgets',
      'es': 'Widgets',
      'ur': 'ویجٹس',
      'id': 'Widget',
    },

    'settings': {
      'en': 'Settings',
      'tr': 'Ayarlar',
      'ar': 'الإعدادات',
      'de': 'Einstellungen',
      'fr': 'Paramètres',
      'es': 'Ajustes',
      'ur': 'ترتیبات',
      'id': 'Pengaturan',
    },
    'name': {
      'en': 'Name',
      'tr': 'İsim',
      'ar': 'الاسم',
      'de': 'Name',
      'fr': 'Nom',
      'es': 'Nombre',
      'ur': 'نام',
      'id': 'Nama',
    },
    'gender': {
      'en': 'Gender',
      'tr': 'Cinsiyet',
      'ar': 'الجنس',
      'de': 'Geschlecht',
      'fr': 'Genre',
      'es': 'Género',
      'ur': 'جنس',
      'id': 'Jenis kelamin',
    },
    'language': {
      'en': 'Language',
      'tr': 'Dil',
      'ar': 'اللغة',
      'de': 'Sprache',
      'fr': 'Langue',
      'es': 'Idioma',
      'ur': 'زبان',
      'id': 'Bahasa',
    },
    'theme': {
      'en': 'Theme',
      'tr': 'Tema',
      'ar': 'المظهر',
      'de': 'Design',
      'fr': 'Thème',
      'es': 'Tema',
      'ur': 'تھیم',
      'id': 'Tema',
    },
    'customize': {
      'en': 'Customize',
      'tr': 'Özelleştir',
      'ar': 'تخصيص',
      'de': 'Anpassen',
      'fr': 'Personnaliser',
      'es': 'Personalizar',
      'ur': 'حسب ضرورت بنائیں',
      'id': 'Sesuaikan',
    },
    'customer_center': {
      'en': 'Customer center',
      'tr': 'Müşteri merkezi',
      'ar': 'مركز الدعم',
      'de': 'Kundencenter',
      'fr': "Centre d'assistance",
      'es': 'Centro de ayuda',
      'ur': 'کسٹمر سینٹر',
      'id': 'Pusat bantuan',
    },
    'profile_picture': {
      'en': 'Profile picture',
      'tr': 'Profil fotoğrafı',
      'ar': 'صورة الملف الشخصي',
      'de': 'Profilbild',
      'fr': 'Photo de profil',
      'es': 'Foto de perfil',
      'ur': 'پروفائل تصویر',
      'id': 'Foto profil',
    },
    'feedback': {
      'en': 'Feedback',
      'tr': 'Geri bildirim',
      'ar': 'ملاحظات',
      'de': 'Feedback',
      'fr': 'Retour',
      'es': 'Comentarios',
      'ur': 'رائے',
      'id': 'Masukan',
    },
    'not_set': {
      'en': 'Not set',
      'tr': 'Belirtilmemiş',
      'ar': 'غير محدد',
      'de': 'Nicht angegeben',
      'fr': 'Non défini',
      'es': 'Sin especificar',
      'ur': 'مقرر نہیں',
      'id': 'Belum diatur',
    },

    'selected': {
      'en': 'Selected',
      'tr': 'Seçildi',
      'ar': 'محدد',
      'de': 'Ausgewählt',
      'fr': 'Sélectionné',
      'es': 'Seleccionado',
      'ur': 'منتخب',
      'id': 'Dipilih',
    },
    'theme_system': {
      'en': 'System',
      'tr': 'Sistem',
      'ar': 'النظام',
      'de': 'System',
      'fr': 'Système',
      'es': 'Sistema',
      'ur': 'سسٹم',
      'id': 'Sistem',
    },
    'theme_light': {
      'en': 'Light',
      'tr': 'Açık',
      'ar': 'فاتح',
      'de': 'Hell',
      'fr': 'Clair',
      'es': 'Claro',
      'ur': 'ہلکا',
      'id': 'Terang',
    },
    'theme_dark': {
      'en': 'Dark',
      'tr': 'Koyu',
      'ar': 'داكن',
      'de': 'Dunkel',
      'fr': 'Sombre',
      'es': 'Oscuro',
      'ur': 'گہرا',
      'id': 'Gelap',
    },

    'theme_subtitle': {
      'en': 'Choose how Quran Verse Reminder looks on your\ndevice',
      'tr': 'Quran Verse Reminder cihazında nasıl\ngörünsün seç',
      'ar': 'اختر كيف يظهر Quran Verse Reminder\nعلى جهازك',
      'de': 'Wähle, wie Quran Verse Reminder auf deinem\nGerät aussieht',
      'fr': 'Choisis l’apparence de Quran Verse Reminder\nsur ton appareil',
      'es': 'Elige cómo se ve Quran Verse Reminder\nen tu dispositivo',
      'ur': 'منتخب کریں کہ Quran Verse Reminder آپ کے\nآلے پر کیسا نظر آئے',
      'id': 'Pilih tampilan Quran Verse Reminder\ndi perangkatmu',
    },
    'legal': {
      'en': 'Legal',
      'tr': 'Yasal',
      'ar': 'القانونية',
      'de': 'Rechtliches',
      'fr': 'Mentions légales',
      'es': 'Legal',
      'ur': 'قانونی',
      'id': 'Legal',
    },
    'privacy_policy': {
      'en': 'Privacy Policy',
      'tr': 'Gizlilik Politikası',
      'ar': 'سياسة الخصوصية',
      'de': 'Datenschutzerklärung',
      'fr': 'Politique de confidentialité',
      'es': 'Política de privacidad',
      'ur': 'رازداری کی پالیسی',
      'id': 'Kebijakan Privasi',
    },
    'terms_of_use': {
      'en': 'Terms of Use',
      'tr': 'Kullanım Şartları',
      'ar': 'شروط الاستخدام',
      'de': 'Nutzungsbedingungen',
      'fr': "Conditions d'utilisation",
      'es': 'Términos de uso',
      'ur': 'استعمال کی شرائط',
      'id': 'Ketentuan Penggunaan',
    },

    'sign_out': {
      'en': 'Sign out',
      'tr': 'Çıkış yap',
      'ar': 'تسجيل الخروج',
      'de': 'Abmelden',
      'fr': 'Se déconnecter',
      'es': 'Cerrar sesión',
      'ur': 'سائن آؤٹ',
      'id': 'Keluar',
    },

    'language_title': {
      'en': 'Language',
      'tr': 'Dil',
      'ar': 'اللغة',
      'de': 'Sprache',
      'fr': 'Langue',
      'es': 'Idioma',
      'ur': 'زبان',
      'id': 'Bahasa',
    },
    'language_subtitle': {
      'en':
          "Choose which language the ayah's translation shows "
          'in below the Arabic',
      'tr':
          'Ayetin çevirisinin Arapçanın altında hangi dilde '
          'gösterileceğini seç',
      'ar': 'اختر اللغة التي تظهر بها ترجمة الآية أسفل النص العربي',
      'de':
          'Wähle, in welcher Sprache die Übersetzung des Verses '
          'unter dem arabischen Text angezeigt wird',
      'fr':
          "Choisissez la langue dans laquelle s'affiche la "
          "traduction du verset sous l'arabe",
      'es':
          'Elige en qué idioma se muestra la traducción del '
          'versículo debajo del árabe',
      'ur':
          'منتخب کریں کہ عربی متن کے نیچے آیت کا ترجمہ کس زبان '
          'میں دکھایا جائے',
      'id':
          'Pilih bahasa terjemahan ayat yang ditampilkan di '
          'bawah teks Arab',
    },

    'show_arabic_title': {
      'en': 'Show Arabic text',
      'tr': 'Arapça metni göster',
      'ar': 'إظهار النص العربي',
      'de': 'Arabischen Text anzeigen',
      'fr': 'Afficher le texte arabe',
      'es': 'Mostrar texto árabe',
      'ur': 'عربی متن دکھائیں',
      'id': 'Tampilkan teks Arab',
    },
    'show_arabic_subtitle': {
      'en': 'Turn off to see only the translation on the home screen',
      'tr': 'Kapatırsan ana sayfada sadece çeviri görünür',
      'ar': 'أوقف هذا الخيار لرؤية الترجمة فقط في الشاشة الرئيسية',
      'de':
          'Ausschalten, um auf der Startseite nur die Übersetzung '
          'zu sehen',
      'fr':
          'Désactivez pour ne voir que la traduction sur l\'écran '
          'd\'accueil',
      'es':
          'Desactívalo para ver solo la traducción en la pantalla '
          'principal',
      'ur': 'صرف ہوم اسکرین پر ترجمہ دیکھنے کے لیے اسے بند کریں',
      'id': 'Matikan untuk hanya melihat terjemahan di beranda',
    },
  };

  /// Monday..Sunday abbreviations for the streak card, in the same order
  /// QuranVerse-adjacent code already uses (server week arrays, DateTime's
  /// own Mon=1..Sun=7).
  static const Map<String, List<String>> _weekdaysShort = {
    'en': ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
    'tr': ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'],
    'ar': ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'],
    'de': ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
    'fr': ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'],
    'es': ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'],
    'ur': ['پیر', 'منگ', 'بدھ', 'جمر', 'جمع', 'ہفت', 'اتو'],
    'id': ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
  };

  static String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[QuranLanguageController.instance.code] ?? entry['en'] ?? key;
  }

  static List<String> weekdaysShort() =>
      _weekdaysShort[QuranLanguageController.instance.code] ??
      _weekdaysShort['en']!;
}
