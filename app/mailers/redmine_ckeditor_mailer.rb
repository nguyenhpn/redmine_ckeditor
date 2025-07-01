class RedmineCkeditorMailer < ActionMailer::Base
  default from: Setting.mail_from # Set the default from email

  def send_notification(mail, subject, html_body)
    #@html_body = html_body
    mail(to: mail, subject: subject) do |format|
      format.html { render html: html_body.html_safe }
    end
  end
end