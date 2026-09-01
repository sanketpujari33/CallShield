import 'package:flutter_test/flutter_test.dart';
import 'package:callshield_app/data/areacodes/area_code_lookup.dart';

void main() {
  group('AreaCodeLookup', () {
    test('resolves US major metropolitan area codes', () {
      expect(AreaCodeLookup.lookup('+12127365000'), equals('New York, NY'));
      expect(AreaCodeLookup.lookup('14155551234'), equals('San Francisco, CA'));
      expect(AreaCodeLookup.lookup('3125551234'), equals('Chicago, IL'));
    });

    test('resolves Toll-Free numbers', () {
      expect(AreaCodeLookup.lookup('+18005551234'), equals('Toll-Free'));
      expect(AreaCodeLookup.lookup('+18885551234'), equals('Toll-Free'));
      expect(AreaCodeLookup.lookup('+18775551234'), equals('Toll-Free'));
    });

    test('resolves Canadian area codes', () {
      expect(AreaCodeLookup.lookup('+14165551234'), equals('Toronto, ON'));
      expect(AreaCodeLookup.lookup('+16045551234'), equals('Vancouver, BC'));
    });

    test('extracts area code prefix string', () {
      expect(AreaCodeLookup.getAreaCode('+12127365000'), equals('212'));
      expect(AreaCodeLookup.getAreaCode('4155551234'), equals('415'));
      expect(AreaCodeLookup.getAreaCode('+442079460999'), isNull);
    });
  });
}
