import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:provider/provider.dart';
import 'package:cartologistics_users_app/appInfo/app_info.dart';
import 'package:cartologistics_users_app/global/global_var.dart';

class PushNotificationService {
  static const Map<String, String> _serviceAccountEnvMap = {
    "type": "GCP_SERVICE_ACCOUNT_TYPE",
    "project_id": "GCP_SERVICE_ACCOUNT_PROJECT_ID",
    "private_key_id": "GCP_SERVICE_ACCOUNT_PRIVATE_KEY_ID",
    "private_key": "GCP_SERVICE_ACCOUNT_PRIVATE_KEY",
    "client_email": "GCP_SERVICE_ACCOUNT_CLIENT_EMAIL",
    "client_id": "GCP_SERVICE_ACCOUNT_CLIENT_ID",
    "auth_uri": "GCP_SERVICE_ACCOUNT_AUTH_URI",
    "token_uri": "GCP_SERVICE_ACCOUNT_TOKEN_URI",
    "auth_provider_x509_cert_url":
        "GCP_SERVICE_ACCOUNT_AUTH_PROVIDER_X509_CERT_URL",
    "client_x509_cert_url": "GCP_SERVICE_ACCOUNT_CLIENT_X509_CERT_URL",
    "universe_domain": "GCP_SERVICE_ACCOUNT_UNIVERSE_DOMAIN",
  };

  static Map<String, String> _buildServiceAccountJson() {
    final missingKeys = <String>[];
    final credentials = <String, String>{};

    _serviceAccountEnvMap.forEach((jsonKey, envKey) {
      final value = dotenv.env[envKey];
      if (value == null || value.isEmpty) {
        missingKeys.add(envKey);
      } else {
        credentials[jsonKey] =
            jsonKey == "private_key" ? value.replaceAll(r'\n', '\n') : value;
      }
    });

    if (missingKeys.isNotEmpty) {
      throw StateError(
        "Missing required service account environment values: ${missingKeys.join(', ')}",
      );
    }

    return credentials;
  }

  static Future<String> getAccessToken() async {
    try {
      final serviceAccountJson = _buildServiceAccountJson();
      List<String> scopes = [
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/firebase.database",
        "https://www.googleapis.com/auth/firebase.messaging"
      ];

      http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
      );

      auth.AccessCredentials credentials =
          await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client,
      );
      client.close();
      return credentials.accessToken.data;
    } catch (e) {
      print("Failed to obtain access token: $e");
      rethrow; // Optionally rethrow the exception
    }
  }

  static sendNotificationToSelectedDriver(
      String deviceToken, BuildContext context, String tripID) async {
    print('device token, ${deviceToken}');
    String dropOffDesitinationAddress =
        Provider.of<AppInfoClass>(context, listen: false)
            .dropOffLocation!
            .placeName
            .toString();
    String pickUpAddress = Provider.of<AppInfoClass>(context, listen: false)
        .pickUpLocation!
        .placeName
        .toString();
    print('pickup address is ${pickUpAddress}');
    final String serverKeyTokenKey = await getAccessToken();
    final String projectId = dotenv.env['GCP_SERVICE_ACCOUNT_PROJECT_ID'] ?? 'everyone-2de50';
    String endpointFirebaseCloudMessaging =
      "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";
    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken,
        'notification': {
          'title': "New Trip Request From $userName",
          'body':
              "PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDesitinationAddress"
        },
        'data': {
          'tripID': tripID,
        }
      }
    };
    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKeyTokenKey'
      },
      body: jsonEncode(message),
    );
    if (response.statusCode == 200) {
      print("Notifcation send successfully. ${response.statusCode}");
    } else {
      print('Failed to send notification, ${response.statusCode}');
    }
  }
}
