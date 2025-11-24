import 'package:digify/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DataPrivacyPage extends StatelessWidget {
  const DataPrivacyPage({super.key});

  Widget _buildOptionRow(BuildContext context,
      {required IconData icon, required String label, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label - Not implemented')),
            );
          },
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Terms of Service',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''Welcome to Digify, developed to provide digital document signing, verification, and collaboration features.
By creating an account or using the App, you agree to the following Terms of Service. If you do not agree, please discontinue use immediately.

1. Eligibility

You must be at least 18 years old to use Digify.
If you use the App on behalf of an organization, you confirm that you have authority to bind the organization to these terms.

2. User Account & Registration

You must provide accurate and complete information during signup.

You are responsible for activity under your account.

Digify is not responsible for unauthorized access resulting from your failure to secure your device or credentials.

3. Use of the Service

You agree not to:

Use Digify for illegal, fraudulent, or harmful activities.

Upload documents that contain viruses, harmful code, or malicious scripts.

Attempt to reverse-engineer, exploit, or damage the App.

Use signatures, identities, or documents that you do not own or have rights to use.

4. Digital Signatures and Verification

Digify provides tools to create, apply, manage, and verify digital signatures.

The legal validity of signatures may vary based on your country’s laws.

Digify does not guarantee legal enforceability unless your jurisdiction explicitly supports digital signatures.

5. Document Storage & Cloud Services

Documents, signatures, and related media may be stored using Firebase, Cloudinary, or local device storage.

Digify is not responsible for downtime, data loss, or service issues caused by third-party providers.

6. AI Features

Digify includes AI features such as:

Image-to-text extraction

Background removal

Signature enhancement

AI-generated output may contain errors, and Digify is not responsible for decisions made based on automated content.

7. Acceptable Use

You agree not to:

Upload copyrighted materials without permission

Impersonate any person or entity

Share illegal content (fraudulent IDs, fake documents, or criminal content)

Attempt to manipulate or bypass signature verification features

Violation may lead to account termination without notice.

8. Payment & Fees

(If applicable in the future)

Digify may offer premium features. Any fees will be disclosed at the time of purchase. All payments are final unless required by law.

9. Termination

We may suspend or terminate your account if:

You violate these Terms

We detect suspicious or fraudulent activity

Required by law or a court order

You may delete your account anytime through the app or by contacting support.

10. Limitation of Liability

Digify is provided “as is” without warranty.
We are not liable for:

Loss of data

Misuse of documents or signatures

Legal validity disputes

Technical failures

Damages arising from user negligence

11. Changes to the Terms

We may update these Terms from time to time.
Continued use of the App means you accept the updated terms.''',
                    style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const Divider(height: 1),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data & Privacy',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF274A31),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        children: [
          _buildSection('Data Management', [
            _buildOptionRow(
              context,
              icon: Icons.download,
              label: 'Request all of my data',
            ),
          ]),
          _buildSection('Legal', [
            _buildOptionRow(
              context,
              icon: Icons.description,
              label: 'Terms of service',
              onTap: () => _showTermsOfService(context),
            ),
            _buildOptionRow(
              context,
              icon: Icons.privacy_tip,
              label: 'Privacy policy',
              onTap: () => _showPrivacyPolicy(context),
            ),
          ]),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Privacy Policy',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''This Privacy Policy explains how Digify collects, uses, stores, and protects your information.

1. Information We Collect
1.1 Personal Information

When you create an account, we may collect:

Name

Email address

Phone number

Address

Profile image

CNIC photos (if required for verification)

1.2 Document & Signature Data

Uploaded documents

Generated signatures

Signature metadata (timestamp, signer name, device info)

Document activity logs for verification

1.3 Device Information

Device model

Operating system

IP address

Location (only when you give permission)

App usage logs

1.4 AI Processing Data

AI features may temporarily process:

Images for background removal

Text extraction

Signature enhancement
Processed data is not used to train any external models.

2. How We Use Your Information

We use your data to:

Provide digital signing and verification features

Secure your account

Improve app performance

Communicate updates or support messages

Prevent fraud and abuse

Store documents in Firebase/Cloudinary

We never sell your data.

3. How Your Data Is Stored

Your data may be stored:

On your device (local storage, Hive)

On Firebase Firestore / Firebase Storage

On Cloudinary (for images or PDFs)

We apply encryption and security protocols but cannot guarantee absolute security.

4. Sharing of Information

We do not share your personal information except:

With your consent

Sharing documents with other users

Organizational signing workflows

Third-party services

Firebase (authentication & database)

Cloudinary (media hosting)

Legal requirements

If required by law, court order, or government request.

5. Your Rights

You have the right to:

Access your data

Download your documents

Update or correct personal info

Delete your account and data

Withdraw permissions (camera, storage, location)

6. Data Retention

We retain your data:

As long as your account is active

Or as long as needed for verification logs
When you delete your account, your data is permanently erased except where legally required.

7. Security Measures

We implement:

Encryption

Authentication checks

Firestore security rules

Restricted access controls

SHA/Hash-based signature verification

However, no system is 100% secure.

8. Children’s Privacy

Digify is not intended for users under 13.
We do not knowingly collect information from minors.

9. Changes to This Policy

We may update this Privacy Policy at any time.
We will notify users when major updates occur.''',
                    style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
