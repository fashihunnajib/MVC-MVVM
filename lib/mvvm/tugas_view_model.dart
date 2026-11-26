import 'package:flutter/foundation.dart';

import '../data/repositori_tugas.dart';
import '../model/tugas.dart';

class TugasViewModel extends ChangeNotifier {
  TugasViewModel(this._repo);

  final RepositoriTugas _repo;
  String? _galat;
  bool _filterBelumSelesai = false;

  List<Tugas> get daftar => _repo.daftar;
  List<Tugas> get daftarTerlihat =>
      _filterBelumSelesai
          ? daftar.where((tugas) => !tugas.selesai).toList()
          : daftar;
  String? get galat => _galat;
  bool get filterBelumSelesai => _filterBelumSelesai;
  int get totalTugas => daftar.length;
  int get jumlahSelesai => daftar.where((tugas) => tugas.selesai).length;

  bool tambah(String input) {
    _galat = validasiJudul(input);
    final berhasil = _galat == null;
    if (berhasil) _repo.tambah(input.trim());
    notifyListeners();
    return berhasil;
  }

  void ubahStatus(int id) {
    _repo.ubahStatus(id);
    notifyListeners();
  }

  void ubahFilter(bool nilai) {
    _filterBelumSelesai = nilai;
    notifyListeners();
  }
}