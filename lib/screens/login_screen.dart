import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> login(BuildContext context) async {
    try {
      // ✅ เข้าสู่ระบบ
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ ดึง role จาก Firestore
      String userId = userCredential.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'user';

        // ✅ นำทางไปยังหน้าที่เหมาะสม
        if (role == 'admin') {
          Navigator.pushNamedAndRemoveUntil(context, '/adminHome', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        // กรณีที่ไม่มีข้อมูล role ใน Firestore
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      debugPrint('🔥 FirebaseAuth Error: $e');
      String errorMessage = _getFirebaseAuthErrorMessage(e);

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
              onPressed: () => Navigator.pop(context),
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

  String _getFirebaseAuthErrorMessage(dynamic error) {
    String errorMessage = 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';

    debugPrint('🔥 Full Error: ${error.toString()}');

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
          break;
        case 'user-disabled':
          errorMessage = 'บัญชีนี้ถูกปิดใช้งาน กรุณาติดต่อฝ่ายสนับสนุน';
          break;
        case 'user-not-found':
          errorMessage = 'ไม่พบบัญชีนี้ กรุณาตรวจสอบอีเมลอีกครั้ง';
          break;
        case 'wrong-password':
          errorMessage = 'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่';
          break;
        case 'too-many-requests':
          errorMessage = 'คุณพยายามเข้าสู่ระบบหลายครั้งเกินไป กรุณารอสักครู่';
          break;
        case 'network-request-failed':
          errorMessage = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อของคุณ';
          break;
        case 'channel-error':
          errorMessage = 'กรุณาใส่ข้อมูลให้ครบถ้วน';
          break;
        case 'invalid-credential':
          errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง กรุณาลองใหม่';
          break;
        default:
          errorMessage = 'เกิดข้อผิดพลาด: ${error.message}';
          debugPrint('🔥 เกิดข้อผิดพลาด: ${error.message}');
      }
    }
    return errorMessage;
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'รีเซ็ตรหัสผ่าน',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'กรุณากรอกอีเมลของคุณ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: Icon(Icons.email, color: Colors.teal),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                await _resetPassword(context, email);
              } else {
                _showErrorDialog(context, 'กรุณากรอกอีเมลก่อนส่งคำขอ');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('ส่งคำขอ',
            style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context, String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSuccessDialog(context, '📩 ส่งลิงก์รีเซ็ตรหัสผ่านไปที่อีเมลของคุณแล้ว');


    } catch (e) {
      String errorMessage = 'เกิดข้อผิดพลาด: กรุณาตรวจสอบอีเมลของคุณ';

      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = 'ไม่พบบัญชีนี้ในระบบ กรุณาตรวจสอบอีเมลอีกครั้ง';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
        } else if (e.code == 'network-request-failed') {
          errorMessage = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อของคุณ';
        } else {
          errorMessage = 'เกิดข้อผิดพลาด: ${e.message}';
        }
      }

      _showErrorDialog(context, errorMessage);
    }
  }



  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('สำเร็จ', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด Dialog แรก
              Navigator.pop(context); // ปิด Dialog ที่สอง (หรือย้อนกลับหน้า)
            },
            child: Text('ตกลง', style: TextStyle(color: Colors.green)),
          ),

        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('ข้อผิดพลาด', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          shadows: [
                            Shadow(
                              color: Colors.tealAccent.withOpacity(0.5),
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'อีเมล',
                          labelStyle: TextStyle(color: Colors.teal),
                          prefixIcon: Icon(Icons.email, color: Colors.teal),
                          filled: true,
                          fillColor: Colors.grey[250],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่าน',
                          labelStyle: TextStyle(color: Colors.teal),
                          prefixIcon: Icon(Icons.lock, color: Colors.teal),
                          filled: true,
                          fillColor: Colors.grey[250],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start, // จัดปุ่มให้อยู่ด้านซ้าย
                        children: [
                          TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            child: Text(
                              'ลืมรหัสผ่าน?',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () {
                          login(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        child: Text(
                          'ยังไม่มีบัญชี? สมัครสมาชิก',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/home'),
                        child: Text(
                          'เข้าใช้โดยไม่เข้าสู่ระบบ',
                          style: TextStyle(
                            color: Colors.deepOrangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
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
}
