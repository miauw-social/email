import smtplib, ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from pika import BlockingConnection, ConnectionParameters, spec
import os, multiprocessing, json
from jinja2 import Environment, FileSystemLoader

class Emailer:
    def __init__(
        self,
    ) -> None:
        self.connection = BlockingConnection(
            ConnectionParameters(
                host=os.getenv("RB_HOST") or "localhost",
                port=os.getenv("RB_PORT") or 5672,
            )
        )
        self.channel = self.connection.channel()
        self.channel.queue_declare("email")
        self.channel.basic_consume("email", on_message_callback=self.callback, auto_ack=True)

    def callback(self, ch, method: spec.Basic.Deliver, properties: spec.BasicProperties, body) -> None:
        data = json.loads(body)
        process = multiprocessing.Process(target=self.send, args=(data["type"], data["sender"], data["recipient"], data["subject"]), kwargs=data["payload"])
        process.start()
        process.join()

    def start(self) -> None:
        print(" [x] Ready")
        self.channel.start_consuming()

    def build_message(self, type: str, **kwargs) -> tuple[str, str]:
        env = Environment(loader=FileSystemLoader("."))
        d1 = env.get_template(f"templates/{type}/index.html").render(**kwargs)
        d2 = env.get_template(f"templates/{type}/index.txt").render(**kwargs)
        return (d1, d2)


    def send(self, type: str, sender: str, recipient: str, subject: str, **kwargs) -> None:
        """sends email to client"""
        html, text = self.build_message(type, **kwargs)
        # build message
        message = MIMEMultipart("alternative")
        message["Subject"] = subject
        message["From"] = sender
        message["To"] = recipient
        # parts
        txt_part = MIMEText(text)
        html_part = MIMEText(html, "html")
        # 
        message.attach(txt_part)
        message.attach(html_part)
        # 
        with smtplib.SMTP("192.168.1.28", 1026) as server:
            server.sendmail(sender, recipient, message.as_string())


if __name__ == "__main__":
    emailer = Emailer()
    emailer.start()