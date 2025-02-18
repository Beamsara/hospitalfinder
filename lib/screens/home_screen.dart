import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'gold_card_info_page.dart';
import 'pharmacy_page.dart';
import 'clinic_page.dart';
import 'health_center_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class LocationSearchDelegate extends SearchDelegate<String> {
  final Position? currentPosition;

  LocationSearchDelegate({this.currentPosition});

  double _calculateDistance(Position? position, double lat, double lng) {
    if (position == null) return 0.0;
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lng,
    ) /
        1000; // Convert to kilometers
  }



  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = ''; // ล้างข้อความค้นหา
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, ''); // ปิดหน้าค้นหา
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text('กรุณาพิมพ์ชื่อสถานพยาบาลเพื่อค้นหา'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('locations')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff') // กรองด้วย prefix
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container();
        }

        final documents = snapshot.data!.docs;

        // คำนวณระยะทางและเรียงลำดับ
        final sortedDocuments = documents.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final distance = _calculateDistance(
            currentPosition,
            data['latitude'],
            data['longitude'],
          );
          return {
            'doc': doc,
            'data': data,
            'distance': distance,
          };
        }).toList()
          ..sort((a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double));

        return ListView.builder(
          padding: EdgeInsets.all(16.0),
          itemCount: sortedDocuments.length,
          itemBuilder: (context, index) {
            final doc = sortedDocuments[index]['doc'] as QueryDocumentSnapshot;
            final data = sortedDocuments[index]['data'] as Map<String, dynamic>;
            final distance = sortedDocuments[index]['distance'] as double;
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;


            // ✅ ตรวจสอบประเภทก่อนแสดง Card
            if (data['type'] != 'ร้านขายยา' && data['type'] != 'คลินิก' && data['type'] != 'สถานีอนามัย') {
              return Container(); // ถ้าไม่ใช่ประเภทที่ต้องการ ไม่แสดง Card
            }

            // ✅ กำหนดไอคอนตามประเภท
            IconData locationIcon;
            switch (data['type']) {
              case 'ร้านขายยา':
                locationIcon = Icons.local_pharmacy;
                break;
              case 'คลินิก':
                locationIcon = Icons.local_hospital;
                break;
              case 'สถานีอนามัย':
                locationIcon = Icons.health_and_safety;
                break;
              default:
                locationIcon = Icons.place; // ค่าเริ่มต้น
            }

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.teal.withOpacity(0.3),
              margin: EdgeInsets.only(bottom: 16.0),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    locationIcon, // ✅ ไอคอนที่เปลี่ยนตามประเภท
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  data['name'] ?? 'ไม่ทราบชื่อ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'ประเภท: ${data['type'] ?? 'ไม่ระบุ'}\nระยะทาง: ${distance.toStringAsFixed(2)} กม.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min, // ให้ Row ใช้พื้นที่เท่าที่จำเป็น
                  children: [
                    if (currentUserId == data['userId'] && currentUserId != null)
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.cyan, Colors.cyanAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.5),
                              blurRadius: 6,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'ของคุณ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (data['userId'] == null)
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepOrange, Colors.orangeAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.5),
                              blurRadius: 6,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'รอยืนยัน',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                  ],
                ),
                onTap: () {
                  _showPinDetailsDialog(context, doc);
                },
              ),
            );
          },
        );


      },
  );
}

  void _showDeleteAlert(BuildContext context) {
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
                    colors: [Colors.red, Colors.redAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'ลบสำเร็จ!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Alert
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
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

  Future<void> _showPinDetailsDialog(BuildContext context, DocumentSnapshot doc) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final data = doc.data() as Map<String, dynamic>;
    final pinOwnerId = data['userId'];
    final String name = data['name'] ?? 'ไม่ทราบชื่อ';
    final String type = data['type'] ?? 'ไม่ระบุ';
    final Timestamp timestamp = data['timestamp'];
    final DateTime pinTime = timestamp.toDate();
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(pinTime);

    // ✅ ดึงข้อมูลรายละเอียดสถานพยาบาลและเวลาทำการ ถ้ามีให้แสดง
    final String? description = data.containsKey('description') ? data['description'] : null;
    final String? openingHours = data.containsKey('openingHours') ? data['openingHours'] : null;
    debugPrint('🔥 description: $description');
    debugPrint('🔥 openingHours: $openingHours');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9, // ปรับขนาดตามหน้าจอ
          height: MediaQuery.of(context).size.height * 0.6, // ตั้งค่าความสูง
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.5),
                        blurRadius: 5,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'รายละเอียดสถานพยาบาล',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildInfoRow(Icons.my_location_rounded, 'ชื่อ: $name'),
                SizedBox(height: 8),
                _buildInfoRow(Icons.category, 'ประเภท: $type'),
                // SizedBox(height: 8),
                // _buildInfoRow(Icons.access_time, 'เวลาที่ปักหมุด: $formattedTime'),

                // ✅ แสดง "รายละเอียดสถานพยาบาล" ถ้ามี
                if (description != null && description.isNotEmpty) ...[
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.description, 'รายละเอียด: $description'),
                ],

                // ✅ แสดง "เวลาทำการ" ถ้ามี
                if (openingHours != null && openingHours.isNotEmpty) ...[
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.schedule, 'เวลาทำการ: $openingHours'),
                ],

                Spacer(), // ดันเนื้อหาไปด้านบน ทำให้ปุ่มอยู่ด้านล่าง
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _navigateToLocation(data['latitude'], data['longitude']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('นำทาง', style: TextStyle(color: Colors.green)),
                      ),
                      SizedBox(width: 8),
                      if (currentUserId == pinOwnerId) ...[
                        TextButton(
                          onPressed: () {
                            // Navigator.of(context).pop();
                            _showEditPinDialog(context, doc.id, data);
                          },
                          child: Text('แก้ไข', style: TextStyle(color: Colors.blue)),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
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
                                            colors: [Colors.red, Colors.redAccent],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.warning_rounded,
                                          color: Colors.white,
                                          size: 60,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'ยืนยันการลบ',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'คุณแน่ใจหรือไม่ว่าต้องการลบหมุดนี้? การลบจะไม่สามารถกู้คืนได้',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.grey,
                                              textStyle: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            child: Text('ยกเลิก'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await FirebaseFirestore.instance
                                                  .collection('locations')
                                                  .doc(doc.id)
                                                  .delete();
                                              Navigator.of(context).pop(); // ปิด Dialog ยืนยัน
                                              Navigator.of(context).pop(); // ปิด Dialog รายละเอียด
                                              _showDeleteAlert(context); // แสดงการลบสำเร็จ
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: Text(
                                              'ลบ',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text('ลบ', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('ปิด'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.teal, size: 22),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  void _showAlertInfo(BuildContext context) {
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
                    colors: [Colors.orange, Colors.redAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 10,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'กรุณากรอกข้อมูลให้ครบถ้วน!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Alert
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8, // เพิ่มเงาให้ปุ่มดูโดดเด่น
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


Future<void> _showDeleteConfirmationDialog(BuildContext context, String docId) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('ยืนยันการลบ'),
      content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบหมุดนี้? การลบจะไม่สามารถกู้คืนได้'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: () async {
            await FirebaseFirestore.instance.collection('locations').doc(docId).delete();
            Navigator.of(context).pop();
          },
          child: Text('ลบ', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

void _navigateToLocation(double latitude, double longitude) {
  final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude";
  launch(googleMapsUrl);
}


  Future<void> _showEditPinDialog(BuildContext parentContext, String docId, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['name']);
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    final openingHoursController = TextEditingController(text: data['openingHours'] ?? '');
    String selectedType = data['type'];
    String? userRole;

    debugPrint("🟢 กำลังเรียก _showEditPinDialog()"); // ✅ ตรวจสอบว่าเข้ามาที่ฟังก์ชัน

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (snapshot.exists) {
          final userData = snapshot.data();
          userRole = userData?['role'] ?? '';
        }
      } catch (e) {
        debugPrint("❌ Error fetching user role: $e");
        userRole = '';
      }
    }

    debugPrint("🔍 User Role: $userRole");

    if (!parentContext.mounted) {
      debugPrint("❌ Context ถูก Dispose แล้ว ไม่สามารถแสดง Dialog ได้");
      return;
    }

    // ✅ ใช้ addPostFrameCallback เพื่อให้ UI พร้อมก่อนเปิด Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("🟢 เรียก showDialog()");

      showDialog(
        context: parentContext,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'แก้ไขหมุด',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อสถานที่',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: Icon(Icons.edit_location_alt, color: Colors.teal),
                      ),
                    ),
                    SizedBox(height: 15),

                    if (userRole == 'ผู้ประกอบการสถานพยาบาล') ...[
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'รายละเอียดสถานพยาบาล',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          prefixIcon: Icon(Icons.description, color: Colors.teal),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: openingHoursController,
                        decoration: InputDecoration(
                          labelText: 'เวลาทำการ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          prefixIcon: Icon(Icons.access_time, color: Colors.teal),
                        ),
                      ),
                      SizedBox(height: 15),
                    ],

                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: [
                        DropdownMenuItem(value: 'ร้านขายยา', child: Text('ร้านขายยา')),
                        DropdownMenuItem(value: 'คลินิก', child: Text('คลินิก')),
                        DropdownMenuItem(value: 'สถานีอนามัย', child: Text('สถานีอนามัย')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          selectedType = value;
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'ประเภทสถานพยาบาล',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: Icon(Icons.local_hospital, color: Colors.teal),
                      ),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(Icons.cancel, color: Colors.red),
                          label: Text('ยกเลิก', style: TextStyle(color: Colors.red)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (nameController.text.isNotEmpty) {
                              final updateData = {
                                'name': nameController.text.trim(),
                                'type': selectedType,
                              };

                              if (userRole == 'ผู้ประกอบการสถานพยาบาล') {
                                updateData['description'] = descriptionController.text.trim();
                                updateData['openingHours'] = openingHoursController.text.trim();
                              }

                              await FirebaseFirestore.instance
                                  .collection('locations')
                                  .doc(docId)
                                  .update(updateData);

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                _showSuccessAlert(parentContext);
                              }
                            } else {
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                _showAlertInfo(parentContext);
                              }
                            }
                          },
                          icon: Icon(Icons.check, color: Colors.white),
                          label: Text('บันทึก', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }








  void _showSuccessAlert(BuildContext context) {
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
                  colors: [Colors.teal, Colors.tealAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 60,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'แก้ไขหมุดสำเร็จ!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // ปิด Dialog แก้ไข
                Navigator.pop(context); // ปิด Dialog ข้อมูล (ตัวเก่าที่ค้างอยู่)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
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
Widget buildSuggestions(BuildContext context) {
  return Center(
    child: Text('พิมพ์ชื่อสถานพยาบาลเพื่อค้นหา'),
  );
}
}


@override
Widget buildSuggestions(BuildContext context) {
  return Center(
    child: Text('พิมพ์ชื่อสถานพยาบาลเพื่อค้นหา'),
  );
}



class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  int _currentIndex = 4; // ค่าเริ่มต้นที่หน้าหลัก

  final List<Widget> _pages = [
    PharmacyPage(), // ร้านขายยา
    ClinicPage(), // คลินิก
    HealthCenterPage(), // สถานีอนามัย
    GoldCardInfoPage(), // ข้อมูลบัตรทอง
  ];

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    }
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        ) /
        1000; // Convert to kilometers
  }

  Future<Map<String, String>> fetchUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
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



  Future<void> _showPinDetailsDialog(BuildContext context, DocumentSnapshot doc) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final data = doc.data() as Map<String, dynamic>;
    final pinOwnerId = data['userId'];
    final String name = data['name'] ?? 'ไม่ทราบชื่อ';
    final String type = data['type'] ?? 'ไม่ระบุ';
    final Timestamp timestamp = data['timestamp'];
    final DateTime pinTime = timestamp.toDate();
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(pinTime);

    // ✅ ดึงข้อมูลรายละเอียดสถานพยาบาลและเวลาทำการ ถ้ามีให้แสดง
    final String? description = data.containsKey('description') ? data['description'] : null;
    final String? openingHours = data.containsKey('openingHours') ? data['openingHours'] : null;
    debugPrint('🔥 description: $description');
    debugPrint('🔥 openingHours: $openingHours');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9, // ปรับขนาดตามหน้าจอ
          height: MediaQuery.of(context).size.height * 0.6, // ตั้งค่าความสูง
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.5),
                        blurRadius: 5,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'รายละเอียดสถานพยาบาล',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildInfoRow(Icons.my_location_rounded, 'ชื่อ: $name'),
                SizedBox(height: 8),
                _buildInfoRow(Icons.category, 'ประเภท: $type'),
                // SizedBox(height: 8),
                // _buildInfoRow(Icons.access_time, 'เวลาที่ปักหมุด: $formattedTime'),

                // ✅ แสดง "รายละเอียดสถานพยาบาล" ถ้ามี
                if (description != null && description.isNotEmpty) ...[
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.description, 'รายละเอียด: $description'),
                ],

                // ✅ แสดง "เวลาทำการ" ถ้ามี
                if (openingHours != null && openingHours.isNotEmpty) ...[
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.schedule, 'เวลาทำการ: $openingHours'),
                ],

                Spacer(), // ดันเนื้อหาไปด้านบน ทำให้ปุ่มอยู่ด้านล่าง
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _navigateToLocation(data['latitude'], data['longitude']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('นำทาง', style: TextStyle(color: Colors.green)),
                      ),
                      SizedBox(width: 8),
                      if (currentUserId == pinOwnerId) ...[
                        TextButton(
                          onPressed: () {
                            // Navigator.of(context).pop();
                            _showEditPinDialog(context, doc.id, data);
                          },
                          child: Text('แก้ไข', style: TextStyle(color: Colors.blue)),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
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
                                            colors: [Colors.red, Colors.redAccent],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.warning_rounded,
                                          color: Colors.white,
                                          size: 60,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'ยืนยันการลบ',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'คุณแน่ใจหรือไม่ว่าต้องการลบหมุดนี้? การลบจะไม่สามารถกู้คืนได้',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.grey,
                                              textStyle: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            child: Text('ยกเลิก'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await FirebaseFirestore.instance
                                                  .collection('locations')
                                                  .doc(doc.id)
                                                  .delete();
                                              Navigator.of(context).pop(); // ปิด Dialog ยืนยัน
                                              Navigator.of(context).pop(); // ปิด Dialog รายละเอียด
                                              _showDeleteAlert(); // แสดงการลบสำเร็จ
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: Text(
                                              'ลบ',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text('ลบ', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('ปิด'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.teal, size: 22),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  void _showAlertInfo(BuildContext context) {
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
                    colors: [Colors.orange, Colors.redAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 10,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'กรุณากรอกข้อมูลให้ครบถ้วน!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Alert
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8, // เพิ่มเงาให้ปุ่มดูโดดเด่น
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

  void _navigateToLocation(double latitude, double longitude) {
    // โค้ดสำหรับเปิด Google Maps หรือแอปนำทาง
    final String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude";
    launch(googleMapsUrl); // ใช้ package 'url_launcher' เพื่อเปิดลิงก์
  }

  Future<void> _showEditPinDialog(BuildContext parentContext, String docId, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['name']);
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    final openingHoursController = TextEditingController(text: data['openingHours'] ?? '');
    String selectedType = data['type'];
    String? userRole;

    debugPrint("🟢 กำลังเรียก _showEditPinDialog()"); // ✅ ตรวจสอบว่าเข้ามาที่ฟังก์ชัน

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (snapshot.exists) {
          final userData = snapshot.data();
          userRole = userData?['role'] ?? '';
        }
      } catch (e) {
        debugPrint("❌ Error fetching user role: $e");
        userRole = '';
      }
    }

    debugPrint("🔍 User Role: $userRole");

    if (!parentContext.mounted) {
      debugPrint("❌ Context ถูก Dispose แล้ว ไม่สามารถแสดง Dialog ได้");
      return;
    }

    // ✅ ใช้ addPostFrameCallback เพื่อให้ UI พร้อมก่อนเปิด Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("🟢 เรียก showDialog()");

      showDialog(
        context: parentContext,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'แก้ไขหมุด',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อสถานที่',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: Icon(Icons.edit_location_alt, color: Colors.teal),
                      ),
                    ),
                    SizedBox(height: 15),

                    if (userRole == 'ผู้ประกอบการสถานพยาบาล') ...[
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'รายละเอียดสถานพยาบาล',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          prefixIcon: Icon(Icons.description, color: Colors.teal),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: openingHoursController,
                        decoration: InputDecoration(
                          labelText: 'เวลาทำการ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          prefixIcon: Icon(Icons.access_time, color: Colors.teal),
                        ),
                      ),
                      SizedBox(height: 15),
                    ],

                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: [
                        DropdownMenuItem(value: 'ร้านขายยา', child: Text('ร้านขายยา')),
                        DropdownMenuItem(value: 'คลินิก', child: Text('คลินิก')),
                        DropdownMenuItem(value: 'สถานีอนามัย', child: Text('สถานีอนามัย')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          selectedType = value;
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'ประเภทสถานพยาบาล',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: Icon(Icons.local_hospital, color: Colors.teal),
                      ),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(Icons.cancel, color: Colors.red),
                          label: Text('ยกเลิก', style: TextStyle(color: Colors.red)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (nameController.text.isNotEmpty) {
                              final updateData = {
                                'name': nameController.text.trim(),
                                'type': selectedType,
                              };

                              if (userRole == 'ผู้ประกอบการสถานพยาบาล') {
                                updateData['description'] = descriptionController.text.trim();
                                updateData['openingHours'] = openingHoursController.text.trim();
                              }

                              await FirebaseFirestore.instance
                                  .collection('locations')
                                  .doc(docId)
                                  .update(updateData);

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                _showSuccessAlert();
                              }
                            } else {
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                                _showAlertInfo(parentContext);
                              }
                            }
                          },
                          icon: Icon(Icons.check, color: Colors.white),
                          label: Text('บันทึก', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _showSuccessAlert() {
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
                    colors: [Colors.teal, Colors.tealAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'แก้ไขหมุดสำเร็จ!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // ปิด Dialog แก้ไข
                  Navigator.pop(context); // ปิด Dialog ข้อมูล (ตัวเก่าที่ค้างอยู่)
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
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


  void _showDeleteAlert() {
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
                    colors: [Colors.red, Colors.redAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'ลบสำเร็จ!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Alert
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
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
            icon: Icon(Icons.search, color: Colors.teal),
            onPressed: () {
              showSearch(
                context: context,
                delegate: LocationSearchDelegate(currentPosition: _currentPosition),
              );
            },
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
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],

      ),
      body:_currentIndex == 4 // ตรวจสอบว่าหน้าปัจจุบันเป็นหน้าหลักหรือไม่
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'สถานพยาบาลที่รองรับบัตรทองในจังหวัดพระนครศรีอยุธยา',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.teal.withOpacity(0.8),
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 5,
                    color: Colors.tealAccent.withOpacity(0.5),
                  ),
                ],
                letterSpacing: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'ที่ใกล้คุณ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal.withOpacity(0.4),
                letterSpacing: 1.1,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.tealAccent.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _currentPosition == null
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('locations')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('ไม่มีข้อมูลสถานพยาบาล'));
                      }

                      final documents = snapshot.data!.docs;

                      // คำนวณระยะทางและเรียงลำดับ
                      final sortedDocuments = documents.map((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>; // แปลงข้อมูล
                        final distance = _calculateDistance(
                          data['latitude'],
                          data['longitude'],
                        );
                        return {
                          'doc': doc,
                          'data': data,
                          'distance': distance,
                        };
                      }).toList()
                        ..sort((a, b) => (a['distance'] as double)
                            .compareTo(b['distance'] as double));

                      return ListView.builder(
                        padding: EdgeInsets.all(16.0),
                        itemCount: sortedDocuments.length,
                        itemBuilder: (context, index) {
                          final doc = sortedDocuments[index]['doc'] as QueryDocumentSnapshot;
                          final data = sortedDocuments[index]['data'] as Map<String, dynamic>;
                          final distance = sortedDocuments[index]['distance'] as double;
                          final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                          // ✅ กำหนด Icon ตามประเภท
                          IconData locationIcon;
                          switch (data['type']) {
                            case 'ร้านขายยา':
                              locationIcon = Icons.local_pharmacy;
                              break;
                            case 'คลินิก':
                              locationIcon = Icons.local_hospital;
                              break;
                            case 'สถานีอนามัย':
                              locationIcon = Icons.health_and_safety;
                              break;
                            default:
                              locationIcon = Icons.place; // ไอคอนเริ่มต้น ถ้าไม่มีข้อมูล
                          }

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: Colors.teal.withOpacity(0.3),
                            margin: EdgeInsets.only(bottom: 16.0),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.teal, Colors.tealAccent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  locationIcon, // ✅ ไอคอนที่เปลี่ยนตามประเภท
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                data['name'] ?? 'ไม่ทราบชื่อ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'ประเภท: ${data['type'] ?? 'ไม่ระบุ'}\nระยะทาง: ${distance.toStringAsFixed(2)} กม.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min, // ให้ Row ใช้พื้นที่เท่าที่จำเป็น
                                children: [
                                  if (currentUserId == data['userId'] && currentUserId != null)
                                    Container(
                                      margin: EdgeInsets.only(right: 8),
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.cyan, Colors.cyanAccent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.teal.withOpacity(0.5),
                                            blurRadius: 6,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.white, size: 18),
                                          SizedBox(width: 4),
                                          Text(
                                            'ของคุณ',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (data['userId'] == null)
                                    Container(
                                      margin: EdgeInsets.only(right: 8),
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.deepOrange, Colors.orangeAccent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.teal.withOpacity(0.5),
                                            blurRadius: 6,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.white, size: 18),
                                          SizedBox(width: 4),
                                          Text(
                                            'รอยืนยัน',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey.shade600,
                                    size: 16,
                                  ),
                                ],
                              ),
                              onTap: () {
                                _showPinDetailsDialog(context, doc);
                              },
                            ),
                          );
                        },
                      );

                    },
                  ),
          ),
        ],
      )
          : _pages[_currentIndex], // ส่วนอื่นที่ไม่ได้อยู่ในหน้าหลัก
      floatingActionButton: FirebaseAuth.instance.currentUser?.uid == null
          ? null  // 🔴 ไม่แสดงปุ่มถ้าเป็นผู้เยี่ยมชม (userId == null)
          : Container(
        margin: EdgeInsets.only(bottom: 20), // ระยะห่างจากขอบล่าง
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/pin');
          },
          backgroundColor: Colors.transparent, // สีพื้นหลังโปร่งใส เพื่อให้เห็น Gradient
          elevation: 0, // ปิดเงา FloatingActionButton
          icon: Icon(Icons.add, color: Colors.white, size: 28),
          label: Text(
            'ไปหน้าปักหมุด',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation:
          CustomFloatingButtonLocation(Alignment(0.0, 0.7)),
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
                  MaterialPageRoute(builder: (context) => PharmacyPage()),
                );
                break;
              case 1: // ไปยังหน้า ClinicPage
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ClinicPage()),
                );
                break;
              case 2: // หน้าหลัก (HomeScreen)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => GoldCardInfoPage()),
                );
                break;
              case 3: // ไปยังหน้า HealthCenterPage
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HealthCenterPage()),
                );
                break;
              case 4: // ไปยังหน้า GoldCardInfoPage
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
                break;
              default:
                break;
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_pharmacy),
              label: 'ร้านขายยา',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital),
              label: 'คลินิก',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'หน้าหลัก',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety),
              label: 'สถานีอนามัย',
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
                  Icons.medical_services,
                  color: Colors.teal,
                ),
              ),
              label: 'สถานพยาบาล',
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
