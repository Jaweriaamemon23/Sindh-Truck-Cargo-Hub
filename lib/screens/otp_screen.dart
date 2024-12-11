import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  OtpScreen({required this.phoneNumber});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Request focus on the first OTP field when the screen is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      otpFocusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Verification'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Phone Verification',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Enter the 6-digit verification code sent to\n${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 20),
                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50,
                      child: TextField(
                        controller: otpControllers[index],
                        focusNode: otpFocusNodes[index],
                        autofocus: index == 0, // Focus the first field
                        decoration: InputDecoration(
                          counterText: '', // Removes "0/1" counter
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue.shade600),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).nextFocus();
                          } else if (value.isEmpty && index > 0) {
                            FocusScope.of(context).previousFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    String otp = otpControllers
                        .map((controller) => controller.text)
                        .join();
                    if (otp.length == 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('OTP Verified: $otp')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid OTP!')),
                      );
                    }
                  },
                  child: Text('Verify OTP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Add logic to resend the OTP if needed
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Resend OTP clicked')),
                    );
                  },
                  child: Text(
                    'Resend Code',
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
