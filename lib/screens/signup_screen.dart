import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user';

  Future<void> register() async {
    try {
      // ✅ เช็คว่าผู้ใช้ใส่ข้อมูลครบหรือไม่
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        throw FirebaseAuthException(code: 'channel-error');
      }

      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
      });

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      // ✅ แปลงข้อความ Error เป็นภาษาไทย
      String errorMessage = _getFirebaseAuthErrorMessage(e);

      // 🛑 แสดง AlertDialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            errorMessage,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ตกลง',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  }

// ✅ ฟังก์ชันช่วยแปลง Firebase Auth Error เป็นข้อความภาษาไทย
  String _getFirebaseAuthErrorMessage(dynamic error) {
    String errorMessage = 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';

    if (error is FirebaseAuthException) {
      String errorCode = error.code;
      String? errorMsg = error.message; // ✅ เก็บ error.message ถ้ามี

      debugPrint('🔥 Error Code: $errorCode');
      debugPrint('🔥 Error Message: $errorMsg');

      switch (errorCode) {
        case 'invalid-email':
          errorMessage = 'กรุณากรอกอีเมลให้ถูกรูปแบบ';
          break;
        case 'channel-error':
          errorMessage = 'กรุณาใส่ข้อมูลให้ครบถ้วน';
          break;
        case 'email-already-in-use':
          errorMessage = 'อีเมลนี้ถูกใช้ไปแล้ว กรุณาใช้อีเมลอื่น';
          break;
        case 'weak-password':
          errorMessage = 'รหัสผ่านของคุณอ่อนเกินไป กรุณาใช้รหัสที่ซับซ้อนขึ้น';
          break;
        case 'too-many-requests':
          errorMessage = 'มีการส่งคำขอมากเกินไป กรุณาลองใหม่ภายหลัง';
          break;
        case 'operation-not-allowed':
          errorMessage = 'การลงทะเบียนด้วยอีเมลถูกปิดใช้งาน กรุณาติดต่อผู้ดูแลระบบ';
          break;
        case 'network-request-failed':
          errorMessage = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อของคุณ';
          break;
        default:
          if (errorMsg != null) {
            errorMessage = 'เกิดข้อผิดพลาด: ${errorMsg}';
          } else {
            errorMessage = 'เกิดข้อผิดพลาด: ${error.toString()}';
          }
          debugPrint('🔥 เกิดข้อผิดพลาด: ${errorMessage}');
      }
    }
    // ✅ เช็คกรณี Error ที่ไม่ใช่ FirebaseAuthException
    else {
      String errorStr = error.toString();

      if (errorStr.contains("dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.createUserWithEmailAndPassword")) {
        errorMessage = 'การลงทะเบียนล้มเหลว กรุณาตรวจสอบข้อมูลอีกครั้ง';
      } else {
        errorMessage = 'เกิดข้อผิดพลาดที่ไม่คาดคิด: ${errorStr}';
      }
    }

    return errorMessage;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.tealAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'สมัครสมาชิก',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.teal.withOpacity(0.1),
                        child: Icon(Icons.person, size: 50, color: Colors.teal),
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'ชื่อ',
                        icon: Icons.person,
                      ),
                      SizedBox(height: 10),
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'นามสกุล',
                        icon: Icons.person_outline,
                      ),
                      SizedBox(height: 10),
                      _buildTextField(
                        controller: _emailController,
                        label: 'อีเมล',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 10),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'รหัสผ่าน',
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'เลือกประเภทผู้ใช้',
                          labelStyle: TextStyle(
                              color: Colors.teal, fontWeight: FontWeight.bold),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.teal),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.tealAccent, width: 2),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'user',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Colors.teal),
                                SizedBox(width: 10),
                                Text(
                                  'ผู้ใช้ธรรมดา',
                                  style: TextStyle(color: Colors.teal),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'provider',
                            child: Row(
                              children: [
                                Icon(Icons.business, color: Colors.teal),
                                SizedBox(width: 10),
                                Text(
                                  'ผู้ประกอบการสถานพยาบาล',
                                  style: TextStyle(color: Colors.teal),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'สมัครสมาชิก',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: Text(
                          'มีบัญชีแล้ว? เข้าสู่ระบบ',
                          style: TextStyle(
                              color: Colors.teal,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal),
        labelText: label,
        labelStyle: TextStyle(color: Colors.teal),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.tealAccent, width: 2),
        ),
      ),
    );
  }
}
