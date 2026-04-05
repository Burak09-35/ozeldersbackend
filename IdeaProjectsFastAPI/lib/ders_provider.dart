import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- DERS MODELİ ---
class Ders {
  int? id;
  String ogretmenId;
  String ogretmenAdi;
  String ogrenciId;
  String ogrenciAdi;
  String konu;
  DateTime tarih;
  int saat;
  int dakika;
  bool odemeAlindi;
  bool katilimTamamlandi;

  Ders({
    this.id,
    required this.ogretmenId,
    required this.ogretmenAdi,
    required this.ogrenciId,
    required this.ogrenciAdi,
    required this.konu,
    required this.tarih,
    required this.saat,
    required this.dakika,
    this.odemeAlindi = false,
    this.katilimTamamlandi = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'ogretmenId': ogretmenId,
      'ogretmenAdi': ogretmenAdi,
      'ogrenciId': ogrenciId,
      'ogrenciAdi': ogrenciAdi,
      'konu': konu,
      'tarih': tarih.toIso8601String(),
      'saat': saat,
      'dakika': dakika,
      'odemeAlindi': odemeAlindi,
      'katilimTamamlandi': katilimTamamlandi,
    };
  }

  factory Ders.fromJson(Map<String, dynamic> json) {
    return Ders(
      id: json['id'],
      ogretmenId: json['ogretmenId'],
      ogretmenAdi: json['ogretmenAdi'],
      ogrenciId: json['ogrenciId'],
      ogrenciAdi: json['ogrenciAdi'],
      konu: json['konu'],
      tarih: DateTime.parse(json['tarih']),
      saat: json['saat'],
      dakika: json['dakika'],
      odemeAlindi: json['odemeAlindi'],
      katilimTamamlandi: json['katilimTamamlandi'],
    );
  }
}

// --- DERS PROVIDER ---
class DersProvider with ChangeNotifier {
  // Chrome testi için localhost, Emülatör için 10.0.2.2 kullanmalısın
  final String _baseUrl = "http://localhost:5000";

  // Verileri tarih bazlı gruplandırarak tutuyoruz
  Map<DateTime, List<Ders>> _dersler = {};

  Map<DateTime, List<Ders>> get dersler => _dersler;

  // 1. VERİLERİ KULLANICIYA ÖZEL ÇEKME
  Future<void> dersleriYukle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      // 1. ID Kontrolü
      if (userId == null) {
        print("DEBUG: HATA - SharedPreferences içinde user_id bulunamadı!");
        return;
      }
      print("DEBUG: Dersler şu ID için çekiliyor -> $userId");

      // 2. HTTP İsteği
      final response = await http.get(
        Uri.parse('$_baseUrl/lessons?user_id=$userId'),
      );

      // 3. Yanıt Kontrolü
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print("DEBUG: Backend'den gelen ham veri sayısı -> ${data.length}");

        _dersler = {}; // Mevcut listeyi sıfırlayıp yeniden dolduruyoruz

        for (var item in data) {
          try {
            Ders d = Ders.fromJson(item);
            // Tarihi sadece Yıl-Ay-Gün olarak normalize ediyoruz (Gruplandırma için kritik)
            DateTime gun = DateTime(d.tarih.year, d.tarih.month, d.tarih.day);

            if (_dersler[gun] != null) {
              _dersler[gun]!.add(d);
            } else {
              _dersler[gun] = [d];
            }
          } catch (e) {
            print("DEBUG: Tekil bir ders işlenirken hata oluştu: $e");
          }
        }

        // 4. Sıralama ve Ekranı Güncelleme
        _sirala();
        notifyListeners();
        print("DEBUG: notifyListeners çalıştı, Takvim ekranı yenilenmeli.");

      } else {
        print("DEBUG: Sunucu hatası döndü. Kod: ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Dersler yüklenirken teknik bir hata oluştu: $e");
    }
  }

  // 2. YENİ DERS EKLEME
  // 2. YENİ DERS EKLEME
  Future<void> dersEkle(Ders yeniDers) async {
    try {
      // TELEFON HAFIZASINDAN GERÇEK ID'YI ALALIM
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      if (userId == null) {
        print("HATA: Kayıtlı kullanıcı bulunamadı, ders eklenemez!");
        return;
      }

      // KRİTİK DÜZELTME:
      // Takvim sayfasından ne gelirse gelsin (test_hoca vs.),
      // biz burada gerçek userId'yi üzerine yazıyoruz.
      yeniDers.ogretmenId = userId;

      final response = await http.post(
        Uri.parse('$_baseUrl/lessons'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(yeniDers.toJson()),
      );

      if (response.statusCode == 200) {
        Ders kaydedilenDers = Ders.fromJson(jsonDecode(response.body));

        DateTime gun = DateTime(kaydedilenDers.tarih.year, kaydedilenDers.tarih.month, kaydedilenDers.tarih.day);

        if (_dersler[gun] != null) {
          _dersler[gun]!.add(kaydedilenDers);
        } else {
          _dersler[gun] = [kaydedilenDers];
        }

        _sirala();
        notifyListeners();
        print("Ders başarıyla kaydedildi: ${kaydedilenDers.id}");
      } else {
        print("Ders ekleme başarısız. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Ders ekleme hatası: $e");
    }
  }

  // 3. DERS GÜNCELLEME (Örn: Ödeme Alındı İşareti)
  Future<void> dersGuncelle(int id, Map<String, dynamic> guncelVeri) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/lessons/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(guncelVeri),
      );

      if (response.statusCode == 200) {
        // Liste karmaşıklaşmaması için en temizi veriyi yeniden çekmektir
        await dersleriYukle();
      }
    } catch (e) {
      print("Güncelleme sırasında hata: $e");
    }
  }

  // Dersleri saatine göre sıralar
  void _sirala() {
    _dersler.forEach((key, list) {
      list.sort((a, b) => (a.saat * 60 + a.dakika).compareTo(b.saat * 60 + b.dakika));
    });
  }

  // İsimle arama fonksiyonu
  List<Ders> ogrenciDersleriniGetirByIsim(String hedefIsim) {
    List<Ders> sonuclar = [];
    for (var gunlukDersler in _dersler.values) {
      var bulunanlar = gunlukDersler.where(
              (ders) => ders.ogrenciAdi.toLowerCase().contains(hedefIsim.toLowerCase())
      );
      sonuclar.addAll(bulunanlar);
    }
    sonuclar.sort((a, b) => b.tarih.compareTo(a.tarih));
    return sonuclar;
  }
}