# Laporan Praktikum: Arsitektur MVC & MVVM dan Pengujian Flutter

## Identitas Mahasiswa
- **Nama:** <Isi Nama Lengkap>
- **NIM:** <Isi NIM>
- **Kelas / Prodi:** <Isi Kelas, misal: 2E / TRPL>
- **Mata Kuliah:** Pemrograman Perangkat Bergerak
- **Repository & Commit:** <Isi tautan repository dan hash commit>

---

## Cara Menjalankan Aplikasi dan Pengujian

Pastikan Flutter SDK terpasang (modul diverifikasi dengan Flutter 3.29.2), lalu jalankan perintah berikut dari folder root `prak_arsitektur_tugas` yang berisi `pubspec.yaml`:

```bash
# 1. Mengunduh dependensi
flutter pub get

# 2. Memeriksa analisis statis kode
flutter analyze

# 3. Menjalankan seluruh unit test dan widget test
flutter test

# 4. Menjalankan hanya widget test fitur filter
flutter test test/filter_test.dart

# 5. Menjalankan aplikasi di Google Chrome
flutter run -d chrome
```

### Berkas Utama yang Diimplementasikan
- `lib/ui/panel_tugas.dart` — Widget panel bersama (`PanelTugas`) yang menampilkan form judul, ringkasan (`jumlahSelesai` dari `totalTugas`), `FilterChip` (`ValueKey('filter-belum-selesai')`), empty state dinamis, dan daftar checkbox tugas.
- `lib/mvc/pengendali_tugas.dart` — Controller (`PengendaliTugas`) yang menyimpan `_filterBelumSelesai`, menyediakan `daftarTerlihat`, `totalTugas`, serta `ubahFilter(bool nilai)`.
- `lib/mvc/layar_mvc.dart` — View MVC (`LayarMvc` / `_LayarMvcState`) yang meneruskan aksi ke `PengendaliTugas` dan memicu rebuild dengan `setState()`.
- `lib/mvvm/tugas_view_model.dart` — ViewModel (`TugasViewModel`) turunan `ChangeNotifier` yang menyimpan `_filterBelumSelesai`, menyediakan `daftarTerlihat` dan `totalTugas`, serta memanggil `notifyListeners()`.
- `lib/mvvm/layar_mvvm.dart` — View MVVM (`LayarMvvm` / `_LayarMvvmState`) yang memakai `ListenableBuilder` untuk membangun ulang `PanelTugas` saat `TugasViewModel` mengirim notifikasi.
- `test/logika_test.dart` — Unit test untuk `PengendaliTugas` (MVC) dan `TugasViewModel` (MVVM).
- `test/layar_test.dart` — Widget test alur form dan ringkasan untuk layar MVC dan MVVM.
- `test/filter_test.dart` — Widget test fitur filter *Belum selesai*, pemulihan daftar saat filter dimatikan, ketetapan ringkasan, dan empty state pada MVC dan MVVM.

---

## Tabel Perbandingan Arsitektur (Bagian D)

| Pertanyaan | Implementasi MVC | Implementasi MVVM |
|---|---|---|
| **Ketika filter diketuk, class mana yang menerima aksi dan menyimpan pilihan?** | **View (`_LayarMvcState`)** menerima callback `onSelected` pada metode `_ubahFilter(bool nilai)` di `lib/mvc/layar_mvc.dart`, lalu meneruskannya ke **Controller (`PengendaliTugas`)** pada metode `ubahFilter(bool nilai)` di `lib/mvc/pengendali_tugas.dart` yang menyimpan status pada field `_filterBelumSelesai`. | **View (`_LayarMvvmState`)** menghubungkan `onSelected` langsung ke **ViewModel (`TugasViewModel`)** pada metode `ubahFilter(bool nilai)` di `lib/mvvm/tugas_view_model.dart`. Class `TugasViewModel` menerima aksi sekaligus menyimpan pilihan pada field `_filterBelumSelesai`. |
| **Apa yang memicu rebuild? Apa akibatnya jika pemicu itu dihapus?** | **Pemicu rebuild:** Pemanggilan `setState(() => _pengendali.ubahFilter(nilai))` di `_LayarMvcState._ubahFilter` (`lib/mvc/layar_mvc.dart`).<br>**Akibat jika dihapus:** `_filterBelumSelesai` di `PengendaliTugas` tetap berubah, tetapi widget `LayarMvc` tidak dijadwalkan rebuild. Di layar, `FilterChip` tidak berubah menjadi terpilih dan item yang sudah selesai tetap tampil; `test/filter_test.dart` gagal pada pengecekan `selected` / daftar yang terlihat. | **Pemicu rebuild:** Pemanggilan `notifyListeners()` di `TugasViewModel.ubahFilter` (`lib/mvvm/tugas_view_model.dart`) yang didengarkan oleh `ListenableBuilder` di `_LayarMvvmState.build` (`lib/mvvm/layar_mvvm.dart`).<br>**Akibat jika dihapus:** `_filterBelumSelesai` di `TugasViewModel` berubah, tetapi `ListenableBuilder` tidak menerima sinyal untuk menjalankan `builder` ulang. Tampilan chip dan daftar tugas tetap sama seperti sebelum diketuk; `test/filter_test.dart` gagal. |
| **Kapan Anda memilih masing-masing pola?** | **Skenario cocok:** Layar tunggal atau form sederhana dengan jumlah aksi dan turunan state yang sedikit.<br>**Kelebihan:** Alur aksi dari callback UI hingga pemanggilan `setState()` mudah ditelusuri langsung dalam satu file layar (`layar_mvc.dart`).<br>**Biaya / risiko:** Setiap aksi baru (seperti `_ubahFilter`) harus dibungkus `setState()` secara manual di View. Jika lupa memanggil `setState()`, data di `PengendaliTugas` berubah tanpa memperbarui layar, dan kelalaian tersebut tidak tertangkap oleh unit test murni pada Controller (harus ditangkap lewat widget test seperti `test/filter_test.dart`). | **Skenario cocok:** Layar dengan *derived UI state* (seperti kombinasi `daftarTerlihat`, `totalTugas`, `jumlahSelesai`, dan `filterBelumSelesai`) atau layar yang logika pembaruan UI-nya perlu diuji menyeluruh tanpa merender widget.<br>**Kelebihan:** Daftar tersaring, ringkasan total, status filter, galat, dan notifikasi pembaruan terpusat pada satu sumber (`TugasViewModel`) sehingga perubahan state dan `notifyListeners()` dapat diuji bersamaan di unit test (`logika_test.dart`).<br>**Biaya / risiko:** Memerlukan pengelolaan lifecycle (`_viewModel.dispose()` di `_LayarMvvmState.dispose()`) dan memastikan View terpasang ke instance `TugasViewModel` yang tepat lewat `ListenableBuilder`. |

---

## Hasil Percobaan Pemicu Rebuild

### 1. Sebelum Dipulihkan (Pemicu Rebuild Dihapus Sementara)

#### a. Versi MVC (`setState` di `_LayarMvcState._ubahFilter` dihapus sementara)
- **Perilaku layar:** Saat chip `Belum selesai` diketuk, nilai `_filterBelumSelesai` di `PengendaliTugas` berubah, namun `PanelTugas` tidak dibangun ulang sehingga status chip tetap tidak terpilih dan tugas yang sudah dicentang tetap terlihat.
- **Potongan keluaran `flutter test test/filter_test.dart`:**
```text
00:02 +0: MVC menyaring tugas belum selesai dan menjaga ringkasan                                                                                                                  
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: true
  Actual: <false>

When the exception was thrown, this was the stack:
#4      main.<anonymous closure> (file:///D:/Poliwangi/KELAS-E-TRPL/Semester3/PemrogramanBergerak/pertemuan15/prak_arsitektur_tugas/test/filter_test.dart:44:7)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1953:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///D:/Poliwangi/KELAS-E-TRPL/Semester3/PemrogramanBergerak/pertemuan15/prak_arsitektur_tugas/test/filter_test.dart line 44
The test description was:
  MVC menyaring tugas belum selesai dan menjaga ringkasan
════════════════════════════════════════════════════════════════════════════════════════════════════
00:02 +0 -1: MVC menyaring tugas belum selesai dan menjaga ringkasan [E]                                                                                                           
  Test failed. See exception logs above.
  The test description was: MVC menyaring tugas belum selesai dan menjaga ringkasan
  

To run this test again: D:\ALLPROGRAMS\flutter-sdk\bin\cache\dart-sdk\bin\dart.exe test D:/Poliwangi/KELAS-E-TRPL/Semester3/PemrogramanBergerak/pertemuan15/prak_arsitektur_tugas/test/filter_test.dart -p vm --plain-name "MVC menyaring tugas belum selesai dan menjaga ringkasan"
00:02 +1 -1: Some tests failed.
```

#### b. Versi MVVM (`notifyListeners()` di `TugasViewModel.ubahFilter` dihapus sementara)
- **Perilaku layar:** Saat chip `Belum selesai` diketuk, nilai `_filterBelumSelesai` berubah di `TugasViewModel`, namun `ListenableBuilder` pada `LayarMvvm` tidak menerima notifikasi sehingga UI tidak berubah.
- **Potongan keluaran `flutter test test/filter_test.dart`:**
```text
00:03 +1: MVVM menyaring tugas belum selesai dan menjaga ringkasan                                                                                                                 
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: true
  Actual: <false>

When the exception was thrown, this was the stack:
#4      main.<anonymous closure> (file:///D:/Poliwangi/KELAS-E-TRPL/Semester3/PemrogramanBergerak/pertemuan15/prak_arsitektur_tugas/test/filter_test.dart:44:7)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1953:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///D:/Poliwangi/KELAS-E-TRPL/Semester3/PemrogramanBergerak/pertemuan15/prak_arsitektur_tugas/test/filter_test.dart line 44
The test description was:
  MVVM menyaring tugas belum selesai dan menjaga ringkasan
════════════════════════════════════════════════════════════════════════════════════════════════════
00:03 +1 -1: MVVM menyaring tugas belum selesai dan menjaga ringkasan [E]                                                                                                          
  Test failed. See exception logs above.
  The test description was: MVVM menyaring tugas belum selesai dan menjaga ringkasan
  

To run this test again: D:\ALLPROGRAMS\flutter-sdk\bin\cache\dart-sdk\bin\dart.exe test D:/Poliwangi/KELAS-E-TRPL/Semester3/PemrogramanBergerak/pertemuan15/prak_arsitektur_tugas/test/filter_test.dart -p vm --plain-name "MVVM menyaring tugas belum selesai dan menjaga ringkasan"
00:03 +1 -1: Some tests failed.
```

---

### 2. Setelah Dipulihkan (Kondisi Akhir Kode)

#### Keluaran `flutter analyze`
```text
Analyzing prak_arsitektur_tugas...                                      
No issues found! (ran in 1.5s)
```

#### Keluaran `flutter test`
```text
00:03 +7: All tests passed!
```

---

## Bukti Tangkapan Layar (`bukti/`)

Keempat tangkapan layar diambil dengan dua tugas yang sama (`Rancang UI Flutter` dicentang selesai dan `Catat hasil pengujian` belum selesai) sehingga ringkasan pada semua kondisi tetap **`1 dari 2 selesai`**:

| Kondisi | Berkas Gambar | Ringkasan & Daftar yang Tampil |
|---|---|---|
| **MVC — Filter Mati** | [mvc-filter-mati.png](bukti/mvc-filter-mati.png) | Ringkasan `1 dari 2 selesai`, chip belum terpilih, 2 tugas tampil. |
| **MVC — Filter Aktif** | [mvc-filter-aktif.png](bukti/mvc-filter-aktif.png) | Ringkasan tetap `1 dari 2 selesai`, chip terpilih, hanya `Catat hasil pengujian` tampil. |
| **MVVM — Filter Mati** | [mvvm-filter-mati.png](bukti/mvvm-filter-mati.png) | Ringkasan `1 dari 2 selesai`, chip belum terpilih, 2 tugas tampil. |
| **MVVM — Filter Aktif** | [mvvm-filter-aktif.png](bukti/mvvm-filter-aktif.png) | Ringkasan tetap `1 dari 2 selesai`, chip terpilih, hanya `Catat hasil pengujian` tampil. |