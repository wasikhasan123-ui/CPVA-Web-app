import 'package:flutter/material.dart';

class CpvaInfo {
  CpvaInfo._();

  static const Color cardHeader = Color(0xFF1F5673);
  static const Color cardHeaderDark = Color(0xFF0D3B52);
  static const Color cardAccent = Color(0xFF2C7DA0);
  static const Color cardAccentLight = Color(0xFF4A90D9);
  static const Color cardBody = Color(0xFFFAFCFA);
  static const Color cardBodyGradient = Color(0xFFF0F7F0);
  static const Color cardBackHeader = Color(0xFF1A4D6B);
  static const Color cardBackAccent = Color(0xFFE3F2FD);

  static const LinearGradient cardHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardHeaderDark, cardHeader],
  );

  static const LinearGradient cardAccentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cardAccent, cardAccentLight],
  );

  static const String orgName = 'CHITTAGONG PRIVATE VETERINARY ASSOCIATION';
  static const String orgNameBn = 'চট্টগ্রাম প্রাইভেট ভেটেরিনারি অ্যাসোসিয়েশন';
  static const String estd = '(Estd. 2018)';

  static const String contactLine1 = 'যোগাযোগ: প্রধান কার্যালয়, চট্টগ্রাম, বাংলাদেশ।';
  static const String contactEmail = 'ইমেইল: info@cpva-bd.org';
  static const String contactWeb = 'ওয়েব: www.cpva-bd.org';
  static const String contactCombined = '$contactEmail | $contactWeb';

  static const String termsHeader = 'MEMBERSHIP TERMS & CONDITIONS';
  static const List<String> termsBn = [
    'এই কার্ডটি চট্টগ্রাম প্রাইভেট ভেটেরিনারি অ্যাসোসিয়েশন (CPVA)-এর সম্পত্তি।',
    'অ্যাসোসিয়েশনের অফিসিয়াল প্রোগ্রাম ও সভায় সদস্য কার্ডটি সাথে রাখা বাধ্যতামূলক।',
    'কার্ডটি হারিয়ে গেলে বা ক্ষতিগ্রস্ত হলে অবিলম্বে কার্যালয়ে জানান।',
  ];

  static const String sigLeft = 'সাধারণ সম্পাদক';
  static const String sigLeftSub = 'CPVA কেন্দ্রীয় কমিটি';
  static const String sigRight = 'সভাপতি';
  static const String sigRightSub = 'CPVA কেন্দ্রীয় কমিটি';

  static const String validityPrefix = 'VALIDITY: ';
  static const String backFooter = 'IF FOUND, PLEASE RETURN TO CPVA OFFICE';

  static const String nameLabel = 'নাম:';
  static const String designationLabel = 'পদবি:';
  static const String idLabel = 'আইডি নং:';
  static const String bloodGroupLabel = 'রক্তের গ্রুপ:';
  static const String photoPlaceholder = 'PHOTO';
  static const String photoHint = '[পাসপোর্ট সাইজের]';

  static const Map<String, String> bloodGroupBn = {
    'A+': 'এ পজিটিভ',
    'A-': 'এ নেগেটিভ',
    'B+': 'বি পজিটিভ',
    'B-': 'বি নেগেটিভ',
    'AB+': 'এবি পজিটিভ',
    'AB-': 'এবি নেগেটিভ',
    'O+': 'ও পজিটিভ',
    'O-': 'ও নেগেটিভ',
    'O +ve': 'ও পজিটিভ',
    'A +ve': 'এ পজিটিভ',
    'B +ve': 'বি পজিটিভ',
    'O -ve': 'ও নেগেটিভ',
  };

  static DateTime cardValidity() {
    final now = DateTime.now();
    return DateTime(now.year + 1, 12, 31);
  }

  static String formatValidity(DateTime d) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}
