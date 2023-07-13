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
    bool prod = Platform.environment["mode"] == "prod";
    final smtpServer = SmtpServer(
      Platform.environment["smtp_host"].toString(),
      port: int.parse(Platform.environment["smtp_port"] as String),
      username: Platform.environment["smtp_username"],
      password: Platform.environment["smtp_password"],
      allowInsecure: !prod,
      ssl: prod,
    );
    final file = File("templates/${data['type']}.html");
    final m = Mustache(map: data["payload"]);
    final message = Message()
      ..from = Address("me@example.com", 'Laura at miauw')
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
