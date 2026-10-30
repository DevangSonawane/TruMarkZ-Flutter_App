import 'package:flutter_test/flutter_test.dart';
import 'package:trumarkz/core/utils/field_text.dart';
import 'package:trumarkz/core/utils/holder_phone.dart';

void main() {
  group('isValidHolderPhone', () {
    test('accepts 10–15 digits with an optional leading +', () {
      expect(isValidHolderPhone('9800000000'), isTrue);
      expect(isValidHolderPhone('+919800000000'), isTrue);
      expect(isValidHolderPhone('+123456789012345'), isTrue);
    });

    test('ignores spaces, dashes, dots and brackets', () {
      expect(isValidHolderPhone('+91 98000-00000'), isTrue);
      expect(isValidHolderPhone('(022) 1234.5678'), isTrue);
    });

    test('rejects too short, too long, letters and misplaced +', () {
      expect(isValidHolderPhone('98000'), isFalse);
      expect(isValidHolderPhone('+1234567890123456'), isFalse);
      expect(isValidHolderPhone('98000abc00'), isFalse);
      expect(isValidHolderPhone('98+00000000'), isFalse);
      expect(isValidHolderPhone(''), isFalse);
    });
  });

  group('holderPhoneError', () {
    test('missing is only an error when required', () {
      expect(holderPhoneError('', required: true), holderPhoneMissingMessage);
      expect(holderPhoneError('  ', required: false), isNull);
    });

    test('an entered number must be valid either way', () {
      expect(holderPhoneError('123', required: false), holderPhoneInvalidMessage);
      expect(holderPhoneError('+91 98000 00000', required: true), isNull);
    });
  });

  test('friendlyFieldText rewords phone_number errors', () {
    expect(
      friendlyFieldText("Value error, 'phone_number' is required"),
      'phone number is required',
    );
  });
}
