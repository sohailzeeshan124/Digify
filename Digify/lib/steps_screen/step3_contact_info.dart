import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class Step3ContactInfo extends StatefulWidget {
  @override
  _Step3ContactInfoState createState() => _Step3ContactInfoState();
}

class _Step3ContactInfoState extends State<Step3ContactInfo> {
  final TextEditingController phoneController = TextEditingController();

  Future<void> requestContactPermission() async {
    final status = await Permission.contacts.request();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status.isGranted
              ? "Contacts Access Granted!"
              : "Contacts Access Denied!",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text("Step 3: Contact Info", style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 19),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: "Phone Number",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 18),
        ElevatedButton(
          onPressed: requestContactPermission,
          child: Text("Allow Contacts Access"),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
