import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/glucose_reading.dart';

class LibreLinkUpConnection {
  String? _patientId;
  String? _apiRegion;
  String? _authToken;
  DateTime? _authExpires;

  final String _email;
  final String _password;

  LibreLinkUpConnection(this._email, this._password);

  final Map<String, String> _requestHeaders = {
    "User-Agent": "Mozilla/5.0",
    "Content-Type": "application/json",
    "product": "llu.ios",
    "version": "4.7.0",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Pragma": "no-cache",
    "Cache-Control": "no-cache",
  };

  Future<void> connectConnection() async {
    try {
      await _processLogin();
    } catch (error) {
      throw Exception('Connection error: $error');
    }
  }

  Future<void> _processLogin({String apiRegion = "de"}) async {
    if (_authToken == null ||
        _authExpires == null ||
        _authExpires!.isBefore(DateTime.now())) {
      var loginResponse = await _login(apiRegion: apiRegion);

      if (loginResponse['status'] == 4) {
        final authToken = loginResponse['data']?['authTicket']?['token'];
        if (authToken == null || authToken.isEmpty) {
          throw LibreLinkError.missingUserOrToken;
        }
        loginResponse = await _tou(apiRegion: apiRegion, authToken: authToken);
      }

      if (loginResponse['data']?['redirect'] == true &&
          loginResponse['data']?['region'] != null) {
        final region = loginResponse['data']['region'];
        await _processLogin(apiRegion: region);
        return;
      }

      final userId = loginResponse['data']?['user']?['id'];
      final responseApiRegion =
          apiRegion ?? loginResponse['data']?['user']?['apiRegion'];
      final authToken = loginResponse['data']?['authTicket']?['token'];
      final authExpires = loginResponse['data']?['authTicket']?['expires'];

      if (userId == null ||
          responseApiRegion == null ||
          authToken == null ||
          authExpires == null) {
        throw LibreLinkError.missingUserOrToken;
      }

      final connectResponse =
          await _connect(apiRegion: responseApiRegion, authToken: authToken);

      _patientId = connectResponse['data'][0]['patientId'];

      if (_patientId == null) {
        throw LibreLinkError.missingPatientID;
      }

      _apiRegion = responseApiRegion;
      _authToken = authToken;
      _authExpires = DateTime.fromMillisecondsSinceEpoch(authExpires * 1000);
    }
  }

  Future<Map<String, dynamic>> _login({String? apiRegion}) async {
    if (_email.isEmpty || _password.isEmpty) {
      throw LibreLinkError.missingCredentials;
    }

    final url = apiRegion != null
        ? 'https://api-$apiRegion.libreview.io/llu/auth/login'
        : 'https://api.libreview.io/llu/auth/login';

    final response = await http.post(
      Uri.parse(url),
      headers: _requestHeaders,
      body: jsonEncode({
        'email': _email,
        'password': _password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 911) {
      throw LibreLinkError.maintenance;
    } else if (response.statusCode == 401) {
      throw LibreLinkError.invalidCredentials;
    }
    throw LibreLinkError.unknownError;
  }

  Future<Map<String, dynamic>> _tou(
      {required String? apiRegion, required String authToken}) async {
    final url = apiRegion != null
        ? 'https://api-$apiRegion.libreview.io/auth/continue/tou'
        : 'https://api.libreview.io/auth/continue/tou';

    final headers = Map<String, String>.from(_requestHeaders)
      ..['Authorization'] = 'Bearer $authToken';

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 911) {
      throw LibreLinkError.maintenance;
    }
    throw LibreLinkError.unknownError;
  }

  Future<Map<String, dynamic>> _connect(
      {required String apiRegion, required String authToken}) async {
    final url = 'https://api-$apiRegion.libreview.io/llu/connections';

    final headers = Map<String, String>.from(_requestHeaders)
      ..['Authorization'] = 'Bearer $authToken';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 911) {
      throw LibreLinkError.maintenance;
    } else if (response.statusCode == 401) {
      throw LibreLinkError.invalidCredentials;
    }
    throw LibreLinkError.unknownError;
  }

  Future<Map<String, dynamic>> fetch() async {
    if (_patientId == null || _apiRegion == null || _authToken == null) {
      throw LibreLinkError.missingLoginSession;
    }

    final url =
        'https://api-$_apiRegion.libreview.io/llu/connections/$_patientId/graph';

    final headers = Map<String, String>.from(_requestHeaders)
      ..['Authorization'] = 'Bearer $_authToken';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 911) {
      throw LibreLinkError.maintenance;
    } else if (response.statusCode == 401) {
      throw LibreLinkError.invalidCredentials;
    }
    throw LibreLinkError.unknownError;
  }

  Future<List<GlucoseReading>> processFetch() async {
    await _processLogin();
    final fetchResponse = await fetch();

    final List<dynamic> graphData = fetchResponse['data']['graphData'] ?? [];
    final connection = fetchResponse['data']['connection'];
    if (connection != null && connection['glucoseMeasurement'] != null) {
      graphData.add(connection['glucoseMeasurement']);
    }

    return graphData.map((data) => GlucoseReading.fromJson(data)).toList();
  }
}

enum LibreLinkError {
  unknownError,
  maintenance,
  invalidURL,
  serializationError,
  missingLoginSession,
  missingUserOrToken,
  missingPatientID,
  invalidCredentials,
  missingCredentials,
  notAuthenticated,
  decoderError,
  missingData,
  parsingError,
  cannotLock,
  missingStatusCode
}
