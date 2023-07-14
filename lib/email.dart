import 'dart:convert';
import 'dart:io';
import 'package:dart_amqp/dart_amqp.dart';
import "package:dart_amqp/dart_amqp.dart" as d;
import 'package:logger/logger.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:simple_mustache/simple_mustache.dart';

class EmailService {
  Logger logger = Logger();

  void sendEmail(data) async {
    logger.i("connecting to smtp server");
    bool prod = Platform.environment["MODE"] == "prod";
    final SmtpServer smtpServer;
    if (prod) {
      smtpServer = SmtpServer(
        Platform.environment["SMTP_HOST"].toString(),
        port: int.parse(Platform.environment["SMTP_PORT"] as String),
        username: Platform.environment["SMTP_USER"],
        password: Platform.environment["SMTP_PASSWORD"],
        allowInsecure: false,
        ssl: true,
      );
    } else {
      smtpServer = SmtpServer(
        Platform.environment["SMTP_HOST"].toString(),
        port: int.parse(Platform.environment["SMTP_PORT"] as String),
        allowInsecure: true,
      );
    }
    final file = File("templates/${data['type']}.html");
    final m = Mustache(map: data["payload"]);
    final message = Message()
      ..from = Address(Platform.environment["SENDER_EMAIL"] as String,
          Platform.environment["SENDER_NAME"])
      ..recipients.add(data["recipient"])
      ..subject = data["subject"]
      ..html = m.convert(await file.readAsString());
    await send(message, smtpServer);
  }

  void main() async {
    logger.i("connecting to rabbitmq");
    Client client =
        Client(settings: d.ConnectionSettings(host: "192.168.1.28"));
    Channel channel = await client.channel();
    Queue queue = await channel.queue("email");
    Consumer consumer = await queue.consume();
    consumer.listen((AmqpMessage message) =>
        sendEmail(jsonDecode(message.payloadAsString)));
  }
}
