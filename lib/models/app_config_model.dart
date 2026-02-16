class TwilioConfig {
  final String accountSid;
  final String authToken;
  final String whatsappNumber;
  final String contentSid;
  final bool enabled;
  final bool useContentTemplate;
  final DateTime? lastUpdated;
  TwilioConfig({
    required this.accountSid,
    required this.authToken,
    required this.whatsappNumber,
    required this.contentSid,
    required this.enabled,
    required this.useContentTemplate,
    this.lastUpdated,
  });
  factory TwilioConfig.fromMap(Map<String, dynamic> map) {
    return TwilioConfig(
      accountSid: map['accountSid'] ?? '',
      authToken: map['authToken'] ?? '',
      whatsappNumber: map['whatsappNumber'] ?? '',
      contentSid: map['contentSid'] ?? '',
      enabled: map['enabled'] ?? false,
      useContentTemplate: map['useContentTemplate'] ?? true,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : null,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'accountSid': accountSid,
      'authToken': authToken,
      'whatsappNumber': whatsappNumber,
      'contentSid': contentSid,
      'enabled': enabled,
      'useContentTemplate': useContentTemplate,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}

class OTPConfig {
  final int otpLength;
  final int expiryMinutes;
  final int maxAttempts;
  final int resendCooldownSeconds;
  final Map<String, String> contentVariables;
  OTPConfig({
    required this.otpLength,
    required this.expiryMinutes,
    required this.maxAttempts,
    required this.resendCooldownSeconds,
    required this.contentVariables,
  });
  factory OTPConfig.fromMap(Map<String, dynamic> map) {
    return OTPConfig(
      otpLength: map['otpLength'] ?? 6,
      expiryMinutes: map['expiryMinutes'] ?? 5,
      maxAttempts: map['maxAttempts'] ?? 3,
      resendCooldownSeconds: map['resendCooldownSeconds'] ?? 60,
      contentVariables: Map<String, String>.from(map['contentVariables'] ??
          {'otpVariable': '1', 'expiryVariable': '2'}),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'otpLength': otpLength,
      'expiryMinutes': expiryMinutes,
      'maxAttempts': maxAttempts,
      'resendCooldownSeconds': resendCooldownSeconds,
      'contentVariables': contentVariables,
    };
  }
}

class PhoneConfig {
  final String defaultCountryCode;
  final List<String> allowedCountryCodes;
  final String phoneValidationRegex;
  PhoneConfig({
    required this.defaultCountryCode,
    required this.allowedCountryCodes,
    required this.phoneValidationRegex,
  });
  factory PhoneConfig.fromMap(Map<String, dynamic> map) {
    return PhoneConfig(
      defaultCountryCode: map['defaultCountryCode'] ?? '+33',
      allowedCountryCodes:
          List<String>.from(map['allowedCountryCodes'] ?? ['+33']),
      phoneValidationRegex: map['phoneValidationRegex'] ?? '^[0-9]{9}\$',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'defaultCountryCode': defaultCountryCode,
      'allowedCountryCodes': allowedCountryCodes,
      'phoneValidationRegex': phoneValidationRegex,
    };
  }
}
