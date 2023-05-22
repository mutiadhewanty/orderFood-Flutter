import 'dart:convert';


import 'package:http/http.dart' as http;

import 'globlas.dart';

class Voucher {
  static Future<http.Response> vouchers(String kode) async {
    Map data = {
      "kode": kode,
    };
    var body = json.encode(data);
    var url = Uri.parse(baseURL + 'vouchers');
    http.Response response = await http.post(
      url,
      headers: headers,
      body: body,
    );
    print(response.body);
    return response;
  }
}
