import smtplib
from email.mime.text import MIMEText
from datetime import datetime

now = datetime.now()
dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

subject = "FME start"
body = "Drogi uzytkowniku $(Destination_e-mail), o godzinie " + dt_string +" rozpoczeto przetwarzanie danych dla gminy $(Powiat)" 
sender = "$(Sender_e-mail)"
recipients = "$(Destination_e-mail)"
password = "xxxx xxxx xxxx xxxx" # key to gmail


def send_email(subject, body, sender, recipients, password):
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = sender
    msg['To'] = ', '.join(recipients)
    with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp_server:
       smtp_server.login(sender, password)
       smtp_server.sendmail(sender, recipients, msg.as_string())


send_email(subject, body, sender, recipients, password)