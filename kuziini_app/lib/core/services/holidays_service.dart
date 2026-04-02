/// Romanian public holidays and weekend info.
class HolidaysService {
  HolidaysService._();

  /// Fixed Romanian public holidays (month, day) → name.
  static const _fixedHolidays = <String, String>{
    '01-01': 'Anul Nou',
    '01-02': 'Anul Nou',
    '01-06': 'Boboteaza',
    '01-07': 'Sf. Ioan',
    '01-24': 'Ziua Unirii',
    '05-01': 'Ziua Muncii',
    '06-01': 'Ziua Copilului',
    '08-15': 'Adormirea Maicii Domnului',
    '11-30': 'Sf. Andrei',
    '12-01': 'Ziua Națională',
    '12-25': 'Crăciun',
    '12-26': 'Crăciun',
  };

  /// Religious and historical descriptions for each holiday.
  static const _holidayDescriptions = <String, String>{
    'Anul Nou': 'Anul Nou marchează începutul unui nou an calendaristic. Este o sărbătoare universală, celebrată cu focuri de artificii, petreceri și urări de bine pentru anul care vine. În tradiția românească, se obișnuiește colindul cu Plugușorul și Sorcova.',
    'Boboteaza': 'Boboteaza (Epifania) comemorează Botezul Domnului Iisus Hristos în râul Iordan de către Sfântul Ioan Botezătorul. În această zi, preotul sfințește apele, iar credincioșii iau agheasmă mare pentru binecuvântarea casei și a familiei.',
    'Sf. Ioan': 'Sfântul Ioan Botezătorul este cel care L-a botezat pe Iisus Hristos. Numit și „Înaintemergătorul", el a pregătit calea Mântuitorului prin predicarea pocăinței. Este una dintre cele mai importante figuri ale creștinismului.',
    'Ziua Unirii': 'Ziua Unirii Principatelor Române (24 ianuarie 1859) comemorează unirea Moldovei cu Țara Românească sub domnitorul Alexandru Ioan Cuza. Este un moment fundamental în formarea statului român modern.',
    'Ziua Muncii': 'Ziua Internațională a Muncii, celebrată pe 1 mai, onorează mișcarea muncitorească și drepturile lucrătorilor. În România este zi liberă și marcată prin evenimente sociale și culturale.',
    'Ziua Copilului': 'Ziua Internațională a Copilului (1 iunie) celebrează drepturile și bunăstarea copiilor din întreaga lume. În România, este zi liberă legală și se organizează evenimente dedicate celor mici.',
    'Vinerea Mare': 'Vinerea Mare (Vinerea Patimilor) comemorează răstignirea și moartea lui Iisus Hristos pe cruce, la Golgota. Este cea mai solemnă zi din Săptămâna Mare, marcată prin post strict și slujbe de priveghere.',
    'Paștele': 'Paștele (Învierea Domnului) este cea mai importantă sărbătoare creștină, celebrând Învierea lui Iisus Hristos din morți, la trei zile după răstignire. Simbolizează triumful vieții asupra morții și speranța mântuirii.',
    'Rusalii': 'Rusaliile (Pogorârea Sfântului Duh) se sărbătoresc la 50 de zile după Paște. Comemorează momentul în care Duhul Sfânt a coborât asupra Apostolilor, dându-le puterea de a predica Evanghelia în toate limbile.',
    'Adormirea Maicii Domnului': 'Adormirea Maicii Domnului (Sfânta Maria Mare, 15 august) celebrează trecerea la cele veșnice a Fecioarei Maria. Este una dintre cele mai venerate sărbători mariane, precedată de Postul Adormirii.',
    'Sf. Andrei': 'Sfântul Apostol Andrei este considerat ocrotitorul României și cel care a adus creștinismul pe meleagurile dacice. A predicat în Dobrogea și Sciția Minor, fiind primul chemat dintre Apostoli.',
    'Ziua Națională': 'Ziua Națională a României (1 decembrie 1918) comemorează Marea Unire – momentul în care Transilvania, Banatul, Crișana și Maramureșul s-au unit cu Regatul României, desăvârșind unitatea națională.',
    'Crăciun': 'Crăciunul celebrează Nașterea Domnului Iisus Hristos în Betleem. Este una dintre cele mai iubite sărbători, marcată prin colinde, brad împodobit, cadouri și masa festivă în familie. Simbolizează lumina, speranța și iubirea.',
  };

  /// Easter dates (Orthodox) for 2024-2030.
  /// Format: year → (month, day) of Easter Sunday.
  static const _easterDates = <int, (int, int)>{
    2024: (5, 5),
    2025: (4, 20),
    2026: (4, 12),
    2027: (5, 2),
    2028: (4, 16),
    2029: (4, 8),
    2030: (4, 28),
  };

  /// Get Easter-related holidays for a year.
  static Map<String, String> _easterHolidays(int year) {
    final easter = _easterDates[year];
    if (easter == null) return {};

    final easterDate = DateTime(year, easter.$1, easter.$2);
    final goodFriday = easterDate.subtract(const Duration(days: 2));
    final easterMonday = easterDate.add(const Duration(days: 1));
    // Rusalii = Easter + 49 days (Pentecost Sunday)
    final rusalii = easterDate.add(const Duration(days: 49));
    final rusaliiMonday = rusalii.add(const Duration(days: 1));

    String fmt(DateTime d) => '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {
      fmt(goodFriday): 'Vinerea Mare',
      fmt(easterDate): 'Paștele',
      fmt(easterMonday): 'Paștele',
      fmt(rusalii): 'Rusalii',
      fmt(rusaliiMonday): 'Rusalii',
    };
  }

  /// Get all holidays for a given year.
  static Map<String, String> getHolidays(int year) {
    return {
      ..._fixedHolidays,
      ..._easterHolidays(year),
    };
  }

  /// Check if a date is a public holiday. Returns holiday name or null.
  static String? getHolidayName(DateTime date) {
    final key = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final holidays = getHolidays(date.year);
    return holidays[key];
  }

  /// Get description for a holiday name.
  static String? getHolidayDescription(String name) => _holidayDescriptions[name];

  /// Check if date is Saturday.
  static bool isSaturday(DateTime date) => date.weekday == 6;

  /// Check if date is Sunday.
  static bool isSunday(DateTime date) => date.weekday == 7;

  /// Check if date is weekend.
  static bool isWeekend(DateTime date) => date.weekday >= 6;

  /// Check if date is a free day (weekend or holiday).
  static bool isFreeDay(DateTime date) => isWeekend(date) || getHolidayName(date) != null;
}
