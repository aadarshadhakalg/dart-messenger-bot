import 'dart:convert';
import 'package:bot/keys.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:dio/dio.dart' as don;

void main(List<String> arguments) async {
  var bot = Router();

  bot.get('/', (Request request) {
    if (request.url.queryParameters['hub.verify_token'] == Keys.VERIFY_TOKEN) {
      return Response.ok(request.url.queryParameters['hub.challenge']);
    } else {
      return Response.ok('Hello! You are not authorized biatch!');
    }
  });

  bot.post('/', (Request request) async {
    var payload = json.decode(
      await request.readAsString(),
    );
    var data = payload['entry'][0]['messaging'];

    for (var msg in data) {
      var text = msg['message']['text'];
      var sender = msg['sender']['id'];
      print('text: $text');
      print('sender: $sender');

      var reply = processMessage(text);

      print('reply: $reply');

      await sendMessage(
        reply: reply,
        recipient: sender,
      );
    }

    return Response.ok('Reply Sent!');
  });

  var server = await io.serve(bot, '127.0.0.1', 8080);
}

String processMessage(String text) {
  String reply;

  switch (text.toLowerCase()) {
    case 'hello':
      reply = 'Hi! How can I help You ?';
      break;
    case 'thanks':
      reply = 'Welcome!';
      break;
    default:
      reply = 'We\'ll reach out to you soon! Thank you for messaging.';
  }

  return reply;
}

Future<void> sendMessage({String reply, String recipient}) async {
  var dio = don.Dio();

  try {
    print('Recipient: $recipient');

    var requestData = {
      'recipient': {'id': recipient},
      'message': {'text': reply}
    };

    print('Request Data:  ${json.encode(requestData)}');
    var response = await dio.post(
      'https://graph.facebook.com/v9.0/me/messages?access_token=${Keys.PAGE_ACCESS_TOKEN}',
      data: json.encode(requestData),
      options: don.Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('Success');
    } else {
      print(response.statusCode);
    }
  } catch (e) {
    print(e.toString());
  }
}
