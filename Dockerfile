FROM dart
WORKDIR /app
COPY . . 
COPY lib/templates /app/templates
ENV SMPT_HOSt="localhost"
ENV SMTP_PORT=1026
ENV SMTP_USER=""
ENV SMTP_PASSWORD=""
ENV SENDER_EMAIL=""
ENV SENDER_NAME=""
ENV MODE="debug"
RUN dart pub get
RUN dart compile exe bin/email_service.dart -o /app/bin/email
ENTRYPOINT [ "/app/bin/email" ]