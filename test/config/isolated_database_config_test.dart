import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:twmt/config/database_config.dart';

void main() {
  group('DatabaseConfig isolated test data root', () {
    test('uses a dedicated directory below APPDATA', () {
      final result = DatabaseConfig.resolveIsolatedAppDataDirectory(
        r'C:\Users\Tester\AppData\Roaming',
      );

      expect(
        result,
        path.join(
          r'C:\Users\Tester\AppData\Roaming',
          DatabaseConfig.isolatedAppDirectoryName,
        ),
      );
      expect(result, isNot(contains(r'com.github.slavyk82\twmt')));
    });

    test('rejects an empty APPDATA path instead of guessing a fallback', () {
      expect(
        () => DatabaseConfig.resolveIsolatedAppDataDirectory('  '),
        throwsArgumentError,
      );
    });

    test('isolated mode is opt-in and disabled for ordinary builds', () {
      expect(DatabaseConfig.isolatedAppDirectoryName, 'TWMT_AI_Test');
      expect(DatabaseConfig.isIsolatedTestBuild, isFalse);
    });
  });
}
