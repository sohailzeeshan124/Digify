import 'package:digify/homepage/home_page.dart';
import 'package:digify/modalclasses/User_modal.dart';
import 'package:digify/viewmodels/User_viewmodal.dart';
import 'package:digify/viewmodels/firebase_viewmodel.dart';
import 'package:flutter/material.dart';
import 'steps_screen/step1_basic_info.dart';
import 'steps_screen/step2_profile_photo.dart';
import 'steps_screen/step3_contact_info.dart';
import 'package:digify/utils/app_colors.dart';

class ProfileCompletionScreen extends StatefulWidget {
  @override
  _ProfileCompletionScreenState createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phonenumberController = TextEditingController();
  final TextEditingController aboutyouController = TextEditingController();

  void nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> finish() async {
    final firebaseviewmodel = FirebaseViewModel();
    final userviewmodel = UserViewModel();

    final userdata = UserData(
      userId: firebaseviewmodel.currentUser!.uid,
      username: userNameController.text,
      displayName: displayNameController.text,
      phoneNumber: phonenumberController.text,
      address: addressController.text,
      aboutyou: aboutyouController.text,
    );

    bool profilecreated = await userviewmodel.saveUserData(userdata);
    if (profilecreated == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Complete Your Profile",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        toolbarHeight: 80,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepProgress(),
            SizedBox(height: 40),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  Step1BasicInfo(
                    displayNameController: displayNameController,
                    userNameController: userNameController,
                    addressController: addressController,
                    phonenumberController: phonenumberController,
                    aboutyouController: aboutyouController,
                  ),
                  Step2ProfilePhoto(),
                  Step3ContactInfo(),
                ],
              ),
            ),
            SizedBox(height: 30),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgress() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStepLine(0)),
            Expanded(child: _buildStepLine(1)),
            Expanded(child: _buildStepLine(2)),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStepIndicator("1", "Basic Info", 0),
            _buildStepIndicator("2", "Profile Photo", 1),
            _buildStepIndicator("3", "Contact Info", 2),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(String stepNumber, String title, int stepIndex) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor:
              _currentStep >= stepIndex
                  ? AppColors.primaryGreen
                  : Colors.grey[400],
          child: Text(
            stepNumber,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStepLine(int stepIndex) {
    return Container(
      height: 4,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color:
            _currentStep > stepIndex
                ? AppColors.primaryGreen
                : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          ElevatedButton(
            onPressed: previousStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
            ),
            child: Text("Back", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        if (_currentStep < 2)
          ElevatedButton(
            onPressed: nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
            ),
            child: Text("Next", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        if (_currentStep == 2)
          ElevatedButton(
            onPressed: finish,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
            ),
            child: Text(
              "Finish",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
