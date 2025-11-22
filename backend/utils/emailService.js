const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD
  }
});

const sendOTPEmail = async (email, otp, name) => {
  const mailOptions = {
    from: process.env.GMAIL_USER,
    to: email,
    subject: 'Smart Doorbell - Email Verification',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #6C63FF;">Smart Doorbell Verification</h2>
        <p>Hello ${name},</p>
        <p>Your verification code for the Smart Doorbell App is:</p>
        <div style="background-color: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
          <h1 style="color: #6C63FF; font-size: 32px; margin: 0;">${otp}</h1>
        </div>
        <p>This code is valid for <strong>5 minutes</strong>.</p>
        <p>If you didn't request this verification, please ignore this email.</p>
        <hr style="margin: 30px 0;">
        <p style="color: #666; font-size: 12px;">Smart Doorbell System © 2025</p>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`OTP email sent to ${email}`);
    return true;
  } catch (error) {
    console.error('Email sending error:', error);
    return false;
  }
};

const sendPasswordResetOTP = async (email, otp, name) => {
  const mailOptions = {
    from: process.env.GMAIL_USER,
    to: email,
    subject: 'Smart Doorbell - Password Reset',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #6C63FF;">Password Reset Request</h2>
        <p>Hello ${name},</p>
        <p>You requested to reset your password for the Smart Doorbell App.</p>
        <p>Your password reset verification code is:</p>
        <div style="background-color: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
          <h1 style="color: #6C63FF; font-size: 32px; margin: 0;">${otp}</h1>
        </div>
        <p>This code is valid for <strong>5 minutes</strong>.</p>
        <p><strong>Important:</strong> If you didn't request a password reset, please ignore this email and your password will remain unchanged.</p>
        <hr style="margin: 30px 0;">
        <p style="color: #666; font-size: 12px;">Smart Doorbell System © 2025</p>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`Password reset OTP email sent to ${email}`);
    return true;
  } catch (error) {
    console.error('Password reset email sending error:', error);
    return false;
  }
};

module.exports = { sendOTPEmail, sendPasswordResetOTP };