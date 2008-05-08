class Notifier < ActionMailer::Base
  
   def payment_notification(payment)
     recipients payment.customer.email_address
     from       "NO-REPLY@framebuilder.com"
     subject    "Your payment has been made"
     content_type "text/html"
     body       :payment => payment
   end
   
   def password_reset_notification(user,password)        #Notifier.deliver_payment_notification(payment)
    recipients user.email
    from       "NO-REPLY@framebuilder.com"
    subject    "Your password has been reset"
    content_type "text/html"
    body       :password=>password
   end
   
end
