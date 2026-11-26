import 'package:flutter/material.dart';

import '../model/tugas.dart';

class PanelTugas extends StatefulWidget {
  const PanelTugas({
    super.key,
    required this.judul,
    required this.daftar,
    required this.jumlahSelesai,
    required this.galat,
    required this.onTambah,
    required this.onUbahStatus,
  });

  final String judul;
  final List<Tugas> daftar;
  final int jumlahSelesai;
  final String? galat;
  final bool Function(String) onTambah;
  final ValueChanged<int> onUbahStatus;

  @override
  State<PanelTugas> createState() => _PanelTugasState();
}

class _PanelTugasState extends State<PanelTugas> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _simpan() {
    if (widget.onTambah(_input.text)) _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.judul)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            key: const ValueKey('judul-tugas'),
            controller: _input,
            decoration: InputDecoration(
              labelText: 'Judul tugas',
              hintText: 'Contoh: Rancang UI Flutter',
              border: const OutlineInputBorder(),
              errorText: widget.galat,
            ),
            onSubmitted: (_) => _simpan(),
          ),
          const SizedBox(height: 10),
          FilledButton(onPressed: _simpan, child: const Text('Tambah tugas')),
          const SizedBox(height: 22),
          Text(
            '${widget.jumlahSelesai} dari ${widget.daftar.length} selesai',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(),
          if (widget.daftar.isEmpty) const Text('Belum ada tugas.'),
          for (final tugas in widget.daftar)
            CheckboxListTile(
              key: ValueKey(tugas.id),
              title: Text(tugas.judul),
              value: tugas.selesai,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (_) => widget.onUbahStatus(tugas.id),
            ),
        ],
      ),
    );
  }
}
