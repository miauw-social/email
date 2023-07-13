# FROM dart
# RUN apt -y update && apt -y upgrade
# WORKDIR /app
# COPY pubspec.yaml .
# RUN ls
# RUN cat pubspec.yaml
# RUN dart pub get
# COPY . .
# RUN dart pub get
# RUN dart compile exe bin/email_service.dart -o /app/bin

# FROM alpine
# WORKDIR /app
# COPY --from=0 /app/ /app/
# ENTRYPOINT [ "/app/bin/server" ]

FROM dart
WORKDIR /app
COPY . . 
COPY lib/templates /app/templates
ENV smtp_host="localhost"
ENV smtp_port=1026
ENV smtp_user=""
ENV smtp_password=""
ENV mode="debug"
RUN dart pub get
RUN dart compile exe bin/email_service.dart -o /app/bin/email
ENTRYPOINT [ "/app/bin/email" ]