import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prak_arsitektur_tugas/main.dart';

void main() {
  for (final mode in ['MVC', 'MVVM']) {
    testWidgets('$mode menyaring tugas belum selesai dan menjaga ringkasan', (
      tester,
    ) async {
      await tester.pumpWidget(const AplikasiTugas());
      await tester.tap(find.text('Buka $mode'));
      await tester.pumpAndSettle();

      final input = find.byKey(const ValueKey('judul-tugas'));
      final tambah = find.text('Tambah tugas');
      final filterChip = find.byKey(const ValueKey('filter-belum-selesai'));

      expect(tester.widget<FilterChip>(filterChip).selected, isFalse);

      // 1. Tambahkan dua tugas, lalu centang tugas pertama.
      await tester.enterText(input, 'Rancang UI Flutter');
      await tester.tap(tambah);
      await tester.pumpAndSettle();

      await tester.enterText(input, 'Catat hasil pengujian');
      await tester.tap(tambah);
      await tester.pumpAndSettle();

      final tugasPertama = find.widgetWithText(
        CheckboxListTile,
        'Rancang UI Flutter',
      );
      await tester.tap(tugasPertama);
      await tester.pumpAndSettle();

      expect(find.text('Rancang UI Flutter'), findsOneWidget);
      expect(find.text('Catat hasil pengujian'), findsOneWidget);
      expect(find.text('1 dari 2 selesai'), findsOneWidget);

      // 2. Aktifkan filter.
      await tester.tap(filterChip);
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(filterChip).selected, isTrue);
      expect(find.text('Rancang UI Flutter'), findsNothing);
      expect(find.text('Catat hasil pengujian'), findsOneWidget);
      expect(find.text('1 dari 2 selesai'), findsOneWidget);

      // 3. Matikan filter.
      await tester.tap(filterChip);
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(filterChip).selected, isFalse);
      expect(find.text('Rancang UI Flutter'), findsOneWidget);
      expect(find.text('Catat hasil pengujian'), findsOneWidget);
      expect(tester.widget<CheckboxListTile>(tugasPertama).value, isTrue);

      // 4. Aktifkan filter lagi, lalu centang tugas kedua.
      await tester.tap(filterChip);
      await tester.pumpAndSettle();

      final tugasKedua = find.widgetWithText(
        CheckboxListTile,
        'Catat hasil pengujian',
      );
      await tester.tap(tugasKedua);
      await tester.pumpAndSettle();

      expect(find.text('Catat hasil pengujian'), findsNothing);
      expect(
        find.text('Tidak ada tugas yang belum selesai.'),
        findsOneWidget,
      );
      expect(find.text('2 dari 2 selesai'), findsOneWidget);
    });
  }
}