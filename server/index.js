import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import Imap from 'imap';
import { simpleParser } from 'mailparser';
import nodemailer from 'nodemailer';

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3001;

// Helper to normalize job title to email format
// "Comercial Natura" -> "comercialnatura"
function jobTitleToEmailPrefix(title) {
  return title
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Remove accents
    .replace(/[^a-z0-9]/g, ''); // Remove non-alphanumeric
}

// Create IMAP connection
function createImapConnection() {
  return new Imap({
    user: process.env.IMAP_USER,
    password: process.env.IMAP_PASSWORD,
    host: process.env.IMAP_HOST,
    port: parseInt(process.env.IMAP_PORT) || 993,
    tls: true,
    tlsOptions: { rejectUnauthorized: false }
  });
}

// Create SMTP transporter
const smtpTransporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT) || 465,
  secure: true,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD
  }
});

// Fetch emails for a specific job
app.get('/api/emails/:jobTitle', async (req, res) => {
  const { jobTitle } = req.params;
  const targetEmail = `${jobTitleToEmailPrefix(jobTitle)}@onav.com.br`;
  
  console.log(`Fetching emails for job: "${jobTitle}" -> ${targetEmail}`);
  console.log(`IMAP Config: ${process.env.IMAP_HOST}:${process.env.IMAP_PORT}`);
  
  const imap = createImapConnection();
  const emails = [];

  try {
    await new Promise((resolve, reject) => {
      imap.once('ready', () => {
        console.log('IMAP connected successfully');
        imap.openBox('INBOX', true, (err, box) => {
          if (err) {
            console.error('Error opening INBOX:', err);
            reject(err);
            return;
          }
          
          console.log(`INBOX opened. Total messages: ${box.messages.total}`);

          // For catch-all, search for the email address in headers using TEXT search
          // This searches the entire email including headers for the target address
          const searchCriteria = [
            ['OR', 
              ['TO', targetEmail],
              ['HEADER', 'X-Original-To', targetEmail]
            ]
          ];
          
          console.log('Searching with criteria:', JSON.stringify(searchCriteria));

          imap.search(searchCriteria, (err, results) => {
            if (err) {
              console.error('Search error:', err);
              // Try a simpler TEXT search as fallback
              console.log('Trying TEXT search fallback...');
              imap.search([['TEXT', targetEmail]], (err2, results2) => {
                if (err2) {
                  reject(err2);
                  return;
                }
                processResults(results2);
              });
              return;
            }
            
            processResults(results);
          });

          function processResults(results) {
            console.log(`Search found ${results?.length || 0} emails`);

            if (!results || results.length === 0) {
              imap.end();
              resolve();
              return;
            }

            // Get the last 50 emails max
            const toFetch = results.slice(-50);
            console.log(`Fetching ${toFetch.length} emails...`);
            const fetch = imap.fetch(toFetch, { bodies: '', struct: true });
            
            const parsePromises = [];

            fetch.on('message', (msg, seqno) => {
              let buffer = '';
              let uid = null;
              
              msg.on('body', (stream) => {
                stream.on('data', (chunk) => {
                  buffer += chunk.toString('utf8');
                });
              });

              msg.once('attributes', (attrs) => {
                uid = attrs.uid;
              });
              
              // Create a promise for each message parsing
              const parsePromise = new Promise((resolveMsg) => {
                msg.once('end', async () => {
                  try {
                    const parsed = await simpleParser(buffer);
                    
                    // Check if this email is actually for our target
                    const toField = (parsed.to?.text || '').toLowerCase();
                    const headers = parsed.headers;
                    const xOriginalTo = headers?.get('x-original-to') || '';
                    const deliveredTo = headers?.get('delivered-to') || '';
                    
                    const isRelevant = 
                      toField.includes(targetEmail.toLowerCase()) ||
                      xOriginalTo.toLowerCase().includes(targetEmail.toLowerCase()) ||
                      deliveredTo.toLowerCase().includes(targetEmail.toLowerCase());
                    
                    if (isRelevant) {
                      emails.push({
                        uid,
                        messageId: parsed.messageId,
                        subject: parsed.subject || '(Sem assunto)',
                        from: parsed.from?.text || '',
                        to: parsed.to?.text || xOriginalTo || '',
                        date: parsed.date?.toISOString() || new Date().toISOString(),
                        snippet: parsed.text?.substring(0, 150) || '',
                        hasAttachments: parsed.attachments?.length > 0
                      });
                      console.log(`Found relevant email: ${parsed.subject}`);
                    }
                  } catch (parseErr) {
                    console.error('Parse error:', parseErr);
                  }
                  resolveMsg();
                });
              });
              
              parsePromises.push(parsePromise);
            });

            fetch.once('error', (err) => {
              console.error('Fetch error:', err);
              reject(err);
            });
            fetch.once('end', async () => {
              console.log('Fetch complete, waiting for parsing...');
              // Wait for all messages to be parsed
              await Promise.all(parsePromises);
              console.log(`Parsed ${emails.length} relevant emails`);
              imap.end();
              resolve();
            });
          }
        });
      });

      imap.once('error', (err) => {
        console.error('IMAP connection error:', err);
        reject(err);
      });
      imap.connect();
    });

    // Sort by date descending
    emails.sort((a, b) => new Date(b.date) - new Date(a.date));
    
    console.log(`Returning ${emails.length} emails`);
    
    res.json({ 
      success: true, 
      targetEmail,
      emails 
    });
  } catch (error) {
    console.error('IMAP Error:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Get single email details
app.get('/api/emails/:jobTitle/:uid', async (req, res) => {
  const { jobTitle, uid } = req.params;
  const targetEmail = `${jobTitleToEmailPrefix(jobTitle)}@onav.com.br`;
  
  console.log(`Fetching email UID ${uid} for job: "${jobTitle}"`);
  
  const imap = createImapConnection();
  let emailData = null;

  try {
    await new Promise((resolve, reject) => {
      imap.once('ready', () => {
        console.log('IMAP connected for single email fetch');
        imap.openBox('INBOX', true, (err) => {
          if (err) {
            reject(err);
            return;
          }

          const fetch = imap.fetch([parseInt(uid)], { bodies: '', struct: true });
          let parsePromise = null;
          
          fetch.on('message', (msg) => {
            let buffer = '';
            
            msg.on('body', (stream) => {
              stream.on('data', (chunk) => {
                buffer += chunk.toString('utf8');
              });
            });

            parsePromise = new Promise((resolveMsg) => {
              msg.once('end', async () => {
                try {
                  const parsed = await simpleParser(buffer);
                  emailData = {
                    uid: parseInt(uid),
                    messageId: parsed.messageId,
                    subject: parsed.subject || '(Sem assunto)',
                    from: parsed.from?.text || '',
                    fromAddress: parsed.from?.value?.[0]?.address || '',
                    to: parsed.to?.text || '',
                    cc: parsed.cc?.text || '',
                    date: parsed.date?.toISOString() || new Date().toISOString(),
                    html: parsed.html || '',
                    text: parsed.text || '',
                    attachments: (parsed.attachments || []).map(att => ({
                      filename: att.filename,
                      contentType: att.contentType,
                      size: att.size
                    }))
                  };
                  console.log(`Parsed email: ${emailData.subject}`);
                } catch (parseErr) {
                  console.error('Parse error:', parseErr);
                }
                resolveMsg();
              });
            });
          });

          fetch.once('error', reject);
          fetch.once('end', async () => {
            console.log('Fetch complete, waiting for parsing...');
            if (parsePromise) {
              await parsePromise;
            }
            console.log('Email parsed, closing connection');
            imap.end();
            resolve();
          });
        });
      });

      imap.once('error', reject);
      imap.connect();
    });

    if (emailData) {
      console.log('Returning email data');
      res.json({ success: true, email: emailData });
    } else {
      console.log('Email not found');
      res.status(404).json({ success: false, error: 'Email not found' });
    }
  } catch (error) {
    console.error('IMAP Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Send/Reply to email
app.post('/api/emails/send', async (req, res) => {
  const { jobTitle, to, subject, html, text, inReplyTo, references } = req.body;
  
  // Hostinger requires sending FROM the authenticated user
  // We use Reply-To for the job-specific email so replies come back correctly
  const senderEmail = process.env.SMTP_USER; // nelson@onav.com.br
  const replyToEmail = `${jobTitleToEmailPrefix(jobTitle)}@onav.com.br`;
  
  console.log(`Sending email from ${senderEmail} (reply-to: ${replyToEmail}) to ${to}`);

  try {
    const mailOptions = {
      from: `"${jobTitle}" <${senderEmail}>`,
      replyTo: replyToEmail,
      to,
      subject,
      text,
      html: html || text,
      ...(inReplyTo && { inReplyTo, references })
    };

    const info = await smtpTransporter.sendMail(mailOptions);
    console.log(`Email sent successfully: ${info.messageId}`);
    
    res.json({ 
      success: true, 
      messageId: info.messageId 
    });
  } catch (error) {
    console.error('SMTP Error:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Email API server running on http://localhost:${PORT}`);
  console.log(`IMAP: ${process.env.IMAP_HOST}`);
  console.log(`SMTP: ${process.env.SMTP_HOST}`);
});
