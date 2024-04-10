// api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'variable.dart';

class ApiService {
  static Future<double> fetchUSDValue() async {
    final response = await http.get(Uri.parse(ApiVariables.coingeckoEndpoint));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['solana']['usd'];
    } else {
      throw Exception('Failed to load USD value');
    }
  }
}
