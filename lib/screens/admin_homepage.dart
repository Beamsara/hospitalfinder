import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospital_finder_app/screens/manage_health_page.dart';
import 'package:hospital_finder_app/screens/manage_user_page.dart';
import 'pharmacy_page.dart';
import 'clinic_page.dart';
import 'home_screen.dart';
import 'health_center_page.dart';

class AdminHomepage extends StatefulWidget {
  @override
  _AdminHomepageState createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userRole; // ✅ เช็ค role ของผู้ใช้
  bool isAdmin = false; // ✅ ค่าคงที่สำหรับเช็คสิทธิ์
  int _currentIndex = 1;

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

  /// ✅ **ฟังก์ชันเพิ่มข้อมูลใหม่**
  void _addNewInfo() {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("เพิ่มข้อมูลใหม่"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "หัวข้อ"),
            ),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: "รายละเอียด"),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                _firestore.collection('gold_card_info').add({
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                  'timestamp': DateTime.now().millisecondsSinceEpoch, // ใช้ timestamp
                });
                Navigator.pop(context);
              }
            },
            child: Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  // ✅ แก้ไขข้อมูล
  void _editInfo(String docId, String currentTitle, String currentContent) {
    TextEditingController titleController =
    TextEditingController(text: currentTitle);
    TextEditingController contentController =
    TextEditingController(text: currentContent);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("แก้ไขข้อมูล"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "หัวข้อ"),
            ),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: "รายละเอียด"),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                _firestore.collection('gold_card_info').doc(docId).update({
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                });
                Navigator.pop(context);
              }
            },
            child: Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  // ✅ ลบข้อมูล
  void _deleteInfo(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ลบข้อมูลนี้?"),
        content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลนี้?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              _firestore.collection('gold_card_info').doc(docId).delete();
              Navigator.pop(context);
            },
            child: Text("ลบ"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
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
          if (isAdmin) // ✅ แสดงปุ่มเพิ่มข้อมูลถ้าผู้ใช้เป็น admin
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _addNewInfo,
            ),
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
      body: _currentIndex == 1
          ? StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('gold_card_info')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("ยังไม่มีข้อมูล"));
          }

          List<Map<String, dynamic>> docs = snapshot.data!.docs
              .map((doc) => {
            'id': doc.id,
            'title': doc['title'] ?? "ไม่มีหัวข้อ",
            'content': doc['content'] ?? "ไม่มีเนื้อหา",
            'timestamp': doc['timestamp'],
          })
              .toList();

          return isAdmin
              ? _buildDraggableExpandableInfoList(docs) // ✅ ถ้าเป็น admin ให้ใช้แบบ Drag & Drop + Expand
              : _buildExpandableInfoList(docs); // ✅ ถ้าไม่ใช่ admin ให้ใช้ Expand อย่างเดียว
        },
      )
          : _pages[_currentIndex], // ✅ แสดงหน้าอื่นตามค่า _currentIndex


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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ManageUserPage()),
                );
                break;
              case 1: // ไปยังหน้า ClinicPage
                setState(() {
                  _currentIndex = index;
                });
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
              icon: Icon(Icons.manage_accounts),
              label: 'จัดการผู้ใช้',
            ),
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
                  Icons.home,
                  color: Colors.teal,
                ),
              ),
              label: 'หน้าหลักAdmin',
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


  /// ✅ **สร้าง UI แบบอ่านอย่างเดียวสำหรับ User**
  Widget _buildReadOnlyInfoList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 10, color: Colors.teal),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                        ),
                        SizedBox(height: 4),
                        Text(item['content'], style: TextStyle(fontSize: 16, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.teal[100]),
          ],
        );
      },
    );
  }

  /// ✅ **สร้าง UI Drag & Drop + Expand**
  Widget _buildDraggableExpandableInfoList(List<Map<String, dynamic>> items) {
    return ReorderableListView.builder(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) => _updateItemOrder(items, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          key: ObjectKey(item), // ✅ ใช้ ObjectKey ป้องกัน Key ซ้ำ
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          margin: EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            title: Text(
              item['title'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  item['content'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              Divider(height: 1, thickness: 1, color: Colors.teal[100]),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ✅ ปุ่มแก้ไข
                  TextButton.icon(
                    onPressed: () => _editInfo(item['id'], item['title'], item['content']),
                    icon: Icon(Icons.edit, color: Colors.blue),
                    label: Text("แก้ไข", style: TextStyle(color: Colors.blue)),
                  ),
                  // ✅ ปุ่มลบ
                  TextButton.icon(
                    onPressed: () => _deleteInfo(item['id']),
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text("ลบ", style: TextStyle(color: Colors.red)),
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔥 **ฟังก์ชันอัปเดตลำดับข้อมูลใน Firebase**
  void _updateItemOrder(List<Map<String, dynamic>> items, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    for (int i = 0; i < items.length; i++) {
      await _firestore.collection('gold_card_info').doc(items[i]['id']).update({
        'timestamp': DateTime.now().millisecondsSinceEpoch + i, // ปรับ timestamp ใหม่
      });
    }
  }

  /// ✅ **สร้าง UI Expand อย่างเดียว**
  Widget _buildExpandableInfoList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          margin: EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            title: Text(
              item['title'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  item['content'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

