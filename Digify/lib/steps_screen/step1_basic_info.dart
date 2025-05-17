import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Step1BasicInfo extends StatelessWidget {
  final TextEditingController userNameController;
  final TextEditingController displayNameController;
  final TextEditingController addressController;
  final TextEditingController phonenumberController;
  final TextEditingController aboutyouController;

  const Step1BasicInfo({
    Key? key,
    required this.displayNameController,
    required this.userNameController,
    required this.addressController,
    required this.phonenumberController,
    required this.aboutyouController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // padding: EdgeInsets.only(
            //   // left: 16,
            //   // right: 16,
            //   // top: 16,
            //   bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            // ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      "Enter your Real name",
                      "Enter your Real name",
                      userNameController,
                    ),
                    _buildTextField(
                      "Enter your address",
                      "Enter your address",
                      addressController,
                    ),
                    _buildTextField(
                      "Enter your phone number",
                      "Enter your phone number",
                      phonenumberController,
                    ),
                    _buildTextField(
                      "Enter something about you",
                      "Enter something about you",
                      aboutyouController,
                    ),
                    _buildTextField(
                      "Enter your displayname",
                      "Enter your display name",
                      displayNameController,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hintText,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          // labelText: label,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.black45),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
