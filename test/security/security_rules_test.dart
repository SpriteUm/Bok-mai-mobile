import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security Rules Tests: Firestore & Storage Rules Specification', () {
    test('firestore.rules file exists and defines essential collections', () {
      final rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue);

      final content = rulesFile.readAsStringSync();

      // Rule must enforce authentication
      expect(content.contains('request.auth != null'), isTrue);

      // Rule must protect public issues and followers
      expect(content.contains('match /issues/{issueId}'), isTrue);
      expect(content.contains('match /issues_feed/{issueId}'), isTrue);
      expect(content.contains('match /followers/{uid}'), isTrue);

      // Rule must enforce reporterId constraints
      expect(content.contains('reporterId'), isTrue);
    });

    test('storage.rules file exists and guards media uploads', () {
      final storageRulesFile = File('storage.rules');
      expect(storageRulesFile.existsSync(), isTrue);

      final content = storageRulesFile.readAsStringSync();
      expect(content.contains('request.auth != null'), isTrue);
      expect(content.contains('match /reports/{issueId}/{file}'), isTrue);
      expect(content.contains('validImage()'), isTrue);
    });
  });
}
