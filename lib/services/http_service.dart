import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:apidash/consts.dart';
import 'package:apidash/models/form_data_model.dart';
import 'package:apidash/models/models.dart';
import 'package:apidash/utils/utils.dart';
import 'package:http/http.dart' as http;

Future<(http.Response?, Duration?, String?)> request(
  RequestModel requestModel, {
  String defaultUriScheme = kDefaultUriScheme,
}) async {
  (Uri?, String?) uriRec = getValidRequestUri(
    requestModel.url,
    requestModel.requestParams,
    defaultUriScheme: defaultUriScheme,
  );
  if (uriRec.$1 != null) {
    Uri requestUrl = uriRec.$1!;
    Map<String, String> headers = requestModel.headersMap;
    http.Response response;
    String? body;
    try {
      var requestBody = requestModel.requestBody;
      if (kMethodsWithBody.contains(requestModel.method) &&
          requestBody != null) {
        var contentLength = utf8.encode(requestBody).length;
        if (contentLength > 0) {
          body = requestBody;
          headers[HttpHeaders.contentLengthHeader] = contentLength.toString();
          headers[HttpHeaders.contentTypeHeader] =
              kContentTypeMap[requestModel.requestBodyContentType] ?? "";
        }
      }
      Stopwatch stopwatch = Stopwatch()..start();
      switch (requestModel.method) {
        case HTTPVerb.get:
          response = await http.get(requestUrl, headers: headers);
          break;
        case HTTPVerb.head:
          response = await http.head(requestUrl, headers: headers);
          break;
        case HTTPVerb.post:
          response = await http.post(requestUrl, headers: headers, body: body);
          break;
        case HTTPVerb.put:
          response = await http.put(requestUrl, headers: headers, body: body);
          break;
        case HTTPVerb.patch:
          response = await http.patch(requestUrl, headers: headers, body: body);
          break;
        case HTTPVerb.delete:
          response =
              await http.delete(requestUrl, headers: headers, body: body);
          break;
      }
      stopwatch.stop();
      return (response, stopwatch.elapsed, null);
    } catch (e) {
      return (null, null, e.toString());
    }
  } else {
    return (null, null, uriRec.$2);
  }
}

Future<(http.Response?, Duration?, String?)> multiPartRequest(
  RequestModel requestModel, {
  String defaultUriScheme = kDefaultUriScheme,
}) async {
  (Uri?, String?) uriRec = getValidRequestUri(
    requestModel.url,
    requestModel.requestParams,
    defaultUriScheme: defaultUriScheme,
  );
  if (uriRec.$1 != null) {
    Uri requestUrl = uriRec.$1!;
    Map<String, String> headers = requestModel.headersMap;
    try {
      var requestBody = requestModel.requestBody;
      if (kMethodsWithBody.contains(requestModel.method) &&
          requestBody != null) {
        var contentLength = utf8.encode(requestBody).length;
        if (contentLength > 0) {
          headers[HttpHeaders.contentLengthHeader] = contentLength.toString();
          headers[HttpHeaders.contentTypeHeader] =
              kContentTypeMap[requestModel.requestBodyContentType] ?? "";
        }
      }
      Stopwatch stopwatch = Stopwatch()..start();

      var request = http.MultipartRequest(
        requestModel.method.name.toUpperCase(),
        requestUrl,
      );
      for (FormDataModel formData in (requestModel.formDataList ?? [])) {
        if (formData.type == FormDataType.text) {
          request.fields.addAll({formData.name: formData.value});
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              formData.name,
              formData.value,
            ),
          );
        }
      }

      http.StreamedResponse response = await request.send();

      stopwatch.stop();
      http.Response convertedHttpResponse =
          await convertStreamedResponse(response);
      return (convertedHttpResponse, stopwatch.elapsed, null);
    } catch (e) {
      return (null, null, e.toString());
    }
  } else {
    return (null, null, uriRec.$2);
  }
}
