import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospital_finder_app/screens/admin_homepage.dart';
import 'package:hospital_finder_app/screens/manage_health_page.dart';
import 'pharmacy_page.dart';
import 'clinic_page.dart';
import 'home_screen.dart';
import 'health_center_page.dart';

class ManageUserPage extends StatefulWidget {
  @override
  _ManageUserPageState createState() => _ManageUserPageState();
}

class _ManageUserPageState extends State<ManageUserPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userRole; // ✅ เช็ค role ของผู้ใช้
  bool isAdmin = false; // ✅ ค่าคงที่สำหรับเช็คสิทธิ์
  int _currentIndex = 0;

  /// ✅ **ดึงรายชื่อผู้ใช้ (ยกเว้น role == 'admin')**
  Stream<QuerySnapshot> _getUsers() {
    return _firestore
        .collection('users')
        .where('role', isNotEqualTo: 'admin')
        // .where('firstName', isNull: false) // ✅ แก้เงื่อนไขให้ถูกต้อง
        .snapshots();
  }


  /// ✅ **แสดง Dialog เพิ่ม/แก้ไข User**
  void _showUserDialog({DocumentSnapshot? userDoc}) {
    final _firstNameController = TextEditingController(
        text: userDoc != null ? userDoc['firstName'] : '');
    final _lastNameController =
    TextEditingController(text: userDoc != null ? userDoc['lastName'] : '');
    final _roleController =
    TextEditingController(text: userDoc != null ? userDoc['role'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          userDoc == null ? 'เพิ่มผู้ใช้ใหม่' : 'แก้ไขข้อมูลผู้ใช้',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'ชื่อ',
                prefixIcon: Icon(Icons.person, color: Colors.teal),
              ),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'นามสกุล',
                prefixIcon: Icon(Icons.person_outline, color: Colors.teal),
              ),
            ),
            TextField(
              controller: _roleController,
              decoration: InputDecoration(
                labelText: 'บทบาท (เช่น user, manager)',
                prefixIcon: Icon(Icons.assignment_ind, color: Colors.teal),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_firstNameController.text.isNotEmpty &&
                  _lastNameController.text.isNotEmpty &&
                  _roleController.text.isNotEmpty) {
                if (userDoc == null) {
                  // ✅ เพิ่มผู้ใช้ใหม่
                  await _firestore.collection('users').add({
                    'firstName': _firstNameController.text.trim(),
                    'lastName': _lastNameController.text.trim(),
                    'role': _roleController.text.trim(),
                  });
                } else {
                  // ✅ แก้ไขข้อมูลผู้ใช้
                  await _firestore.collection('users').doc(userDoc.id).update({
                    'firstName': _firstNameController.text.trim(),
                    'lastName': _lastNameController.text.trim(),
                    'role': _roleController.text.trim(),
                  });
                }
                Navigator.pop(context);
              }
            },
            child: Text(userDoc == null ? 'เพิ่ม' : 'บันทึก'),
          ),
        ],
      ),
    );
  }

  /// ✅ **ลบผู้ใช้**
  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'ยืนยันการลบ',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text('คุณต้องการลบผู้ใช้นี้ใช่หรือไม่? การลบจะไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('users').doc(userId).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  /// ✅ ดึง role ของ user
  Future<void> _fetchUserRole() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      final data = snapshot.data();
      if (data != null && data.containsKey('role')) {
        setState(() {
          userRole = data['role'];
          // debugPrint(userRole);
          isAdmin = (userRole == 'admin'); // ✅ ถ้า role เป็น admin กำหนดค่า true
        });
      }
    }
  }

  final List<Widget> _pages = [
    PharmacyPage(),
    ClinicPage(),
    HomeScreen(),
  ];




  // ✅ ดึงข้อมูลโปรไฟล์จาก Firebase
  Future<Map<String, String>> fetchUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      final data = snapshot.data() as Map<String, dynamic>?;
      return {
        'firstname': data?['firstName'] ?? 'ผู้เยี่ยมชม',
        'lastname': data?['lastName'] ?? 'ผู้เยี่ยมชม',
      };
    }
    return {'firstname': 'ผู้เยี่ยมชม', 'lastname': 'ผู้เยี่ยมชม'};
  }

  Future<void> _showEditNameAndPasswordDialog(
      BuildContext context, String firstName, String lastName) async {
    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'แก้ไขข้อมูล',
                  style: TextStyle(
                    fontSize: 24,
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
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อ',
                    labelStyle: TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.teal, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.tealAccent, width: 2),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.teal),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'นามสกุล',
                    labelStyle: TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.teal, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.tealAccent, width: 2),
                    ),
                    prefixIcon: Icon(Icons.person_outline, color: Colors.teal),
                  ),
                ),
                Divider(height: 30, color: Colors.teal.withOpacity(0.5)),
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านเดิม',
                    labelStyle: TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.teal, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.tealAccent, width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.teal),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านใหม่',
                    labelStyle: TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.teal, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.tealAccent, width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.teal),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'ยืนยันรหัสผ่านใหม่',
                    labelStyle: TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.teal, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.tealAccent, width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.teal),
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.cancel, color: Colors.red),
                      label: Text('ยกเลิก', style: TextStyle(color: Colors.red)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        final user = FirebaseAuth.instance.currentUser;

                        if (userId != null) {
                          // เปลี่ยนชื่อและนามสกุล
                          await FirebaseFirestore.instance.collection('users').doc(userId).update({
                            'firstName': firstNameController.text.trim(),
                            'lastName': lastNameController.text.trim(),
                          });

                          // เปลี่ยนรหัสผ่าน (ถ้าระบุข้อมูล)
                          if (oldPasswordController.text.isNotEmpty ||
                              newPasswordController.text.isNotEmpty ||
                              confirmPasswordController.text.isNotEmpty) {
                            if (newPasswordController.text == confirmPasswordController.text) {
                              try {
                                final cred = EmailAuthProvider.credential(
                                    email: user!.email!, password: oldPasswordController.text);
                                await user.reauthenticateWithCredential(cred);
                                await user.updatePassword(newPasswordController.text);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('รหัสผ่านเปลี่ยนสำเร็จ')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('รหัสผ่านเก่าไม่ถูกต้อง')),
                                );
                                return;
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('รหัสผ่านใหม่ไม่ตรงกัน')),
                              );
                              return;
                            }
                          }

                          Navigator.pop(context);
                          setState(() {}); // Refresh UI
                          _showSuccessAlertProfile(context);
                        }
                      },

                      icon: Icon(Icons.check, color: Colors.white),
                      label: Text('บันทึก', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessAlertProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.greenAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 10,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.verified_user, // เปลี่ยนจาก check_circle เป็นไอคอนเกี่ยวกับโปรไฟล์
                  color: Colors.white,
                  size: 60,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'แก้ไขข้อมูลสำเร็จ!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'ข้อมูลของคุณถูกอัปเดตเรียบร้อยแล้ว 🎉',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Alert
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  'ตกลง',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
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
        elevation: 0,
        backgroundColor: Colors.white,
        title: FutureBuilder<Map<String, String>>(
          future: fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Row(
                children: [
                  CircleAvatar(
                    child: Icon(Icons.person, color: Colors.white),
                    backgroundColor: Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ไม่พบข้อมูล',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              );
            }
            final userData = snapshot.data!;

// 🔥 ตรวจสอบค่าของ userData['firstname']
            debugPrint('🔥 userData: $userData');

// ✅ ดึงตัวอักษรตัวแรกมาใช้เป็น Avatar
            final initial = userData['firstname']!.isNotEmpty
                ? userData['firstname']![0].toUpperCase()
                : '?';

// ✅ ตรวจสอบว่าผู้ใช้เป็น "ผู้เยี่ยมชม"
            final isGuest = userData['firstname'] == 'ผู้เยี่ยมชม';

            return GestureDetector(
              onTap: isGuest
                  ? null  // 🔴 ถ้าเป็น "ผู้เยี่ยมชม" ปิดการกดปุ่ม
                  : () => _showEditNameAndPasswordDialog(
                context,
                userData['firstname']!,
                userData['lastname']!,
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.4),
                          blurRadius: 10,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey,
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${userData['firstname']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${userData['lastname']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

          },
        ),
        actions: [
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.logout,
                color: Colors.white,
                size: 24,
              ),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: _currentIndex == 0
          ? StreamBuilder<QuerySnapshot>(
        stream: _getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('ไม่มีผู้ใช้ที่สามารถจัดการได้'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.all(10),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Text(
                      data['firstName'][0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  title: Text(
                    '${data['firstName']} ${data['lastName']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('บทบาท: ${data['role']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showUserDialog(userDoc: user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      )
          : _pages[_currentIndex],
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () => _showUserDialog(),
      //   icon: Icon(Icons.add),
      //   label: Text('เพิ่มผู้ใช้'),
      //   backgroundColor: Colors.teal,
      // ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.tealAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.4),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          onTap: (index) {
            switch (index) {
              case 0: // ไปยังหน้า PharmacyPage
                setState(() {
                  _currentIndex = index;
                });
                break;
              case 1: // ไปยังหน้า ClinicPage
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminHomepage()),
                );
                break;
              case 2: // หน้าหลัก (HomeScreen)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ManageHealthPage()),
                );
                break;
              default:
                break;
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.6),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.manage_accounts,
                  color: Colors.teal,
                ),
              ),
              label: 'จัดการผู้ใช้',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'หน้าหลัก Admin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_history),
              label: 'จัดการสถานพยาบาล',
            ),
          ],
        ),
      ),
    );
  }
}

class CustomFloatingButtonLocation extends FloatingActionButtonLocation {
  final Alignment alignment;
  CustomFloatingButtonLocation(this.alignment);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final scaffoldSize = scaffoldGeometry.scaffoldSize;
    final fabSize = scaffoldGeometry.floatingActionButtonSize!;
    return Offset(
      scaffoldSize.width * (alignment.x + 1) / 2 - fabSize.width / 2,
      scaffoldSize.height * (alignment.y + 1) / 2 - fabSize.height / 2,
    );
  }
}

