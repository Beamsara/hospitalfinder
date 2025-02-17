import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data'; // สำหรับ Uint8List
import 'dart:ui' as ui;

class PinScreen extends StatefulWidget {
  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  LatLng? _currentPosition;
  String? _selectedType;
  Map<MarkerId, Marker> _markers = {};
  MapType _currentMapType = MapType.normal; // Default map type

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadExistingPins();
  }

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
        _currentPosition = LatLng(position.latitude, position.longitude);
        if (_mapController != null && _currentPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 16),
          );
        }
      });

      // Add current position marker
      final currentMarker = Marker(
        markerId: MarkerId("current_position"),
        position: _currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        // ใช้สีเขียวที่โดดเด่น
        infoWindow: InfoWindow(
          title: "ตำแหน่งปัจจุบัน",
          snippet: "คุณอยู่ที่นี่",
          onTap: () {
            // เพิ่มการโต้ตอบเมื่อกด InfoWindow
            showDialog(
              context: context,
              builder: (context) =>
                  Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 50,
                            color: Colors.green,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'ตำแหน่งปัจจุบัน',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'คุณสามารถใช้ตำแหน่งนี้ในการนำทาง',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'ตกลง',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            );
          },
        ),
      );
      setState(() {
        _markers[MarkerId("current_position")] = currentMarker;
      });
    }
  }

  // ฟังก์ชัน _refreshScreen
  void _refreshScreen() {
    // เรียก setState เพื่ออัปเดตหน้าจอ
    setState(() {
      _markers.clear(); // ล้าง Marker เก่า
      _loadExistingPins(); // โหลด Marker ใหม่จากฐานข้อมูล
    });
  }

  Future<Uint8List> createCustomMarkerBitmap(String text, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = const Size(80, 80); // ลดขนาด Marker

    // วาดพื้นหลังวงกลมพร้อม Gradient
    final gradient = RadialGradient(
      colors: [color.withOpacity(0.9), Colors.white.withOpacity(0.7)],
      center: Alignment.center,
      radius: 0.8,
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, paint);

    // เพิ่มขอบวงกลม
    final borderPaint = Paint()
      ..color = Colors.blue.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2 - 1.5, borderPaint);

    // เพิ่มเงาให้วงกลม
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, shadowPaint);

    // วาดไอคอนสถานพยาบาลตรงกลาง
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: '🏥', // ใช้ไอคอนโรงพยาบาล
        style: const TextStyle(
          fontSize: 30, // ปรับขนาดให้พอดี Marker ที่เล็กลง
          color: Colors.red,
        ),
      ),
    );
    textPainter.layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2 - 5),
    );

    // วาดชื่อหรือข้อความที่ด้านล่าง
    final labelPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 12, // ลดขนาดให้พอดีกับ Marker
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    labelPainter.layout(maxWidth: size.width - 10);
    labelPainter.paint(
      canvas,
      Offset((size.width - labelPainter.width) / 2, size.height - 20),
    );

    // แปลงเป็นภาพ
    final img = await pictureRecorder.endRecording().toImage(
        size.width.toInt(), size.height.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }



  Future<void> _loadExistingPins() async {
    QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('locations').get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final LatLng position = LatLng(data['latitude'], data['longitude']);
      final String name = data['name'];
      final Uint8List markerIcon = await createCustomMarkerBitmap(
          name, Colors.blueAccent);
      final marker = Marker(
        markerId: MarkerId(doc.id),
        position: position,
        icon: BitmapDescriptor.fromBytes(markerIcon),
        infoWindow: InfoWindow(title: name),
      );

      setState(() {
        _markers[MarkerId(doc.id)] = marker;
      });
    }
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

  void _showSaveLocationDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController openingHoursController = TextEditingController();

    String? userRole;

    // 🔥 ดึง role ของ user
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final data = snapshot.data();
      userRole = data?['role'] ?? ''; // ถ้าไม่มีค่า role จะเป็นค่าว่าง
    }
    debugPrint('🧑UserRole: $userRole');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(Icons.location_on, color: Colors.white, size: 50),
                ),
                SizedBox(height: 15),
                Text(
                  'บันทึกสถานที่',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // จัดข้อความให้ชิดซ้าย
                  children: [
                    Text(
                      '*จำเป็นต้องกรอก', // ข้อความเตือน
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อสถานที่',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        prefixIcon: Icon(Icons.edit_location_alt, color: Colors.teal),
                      ),
                    ), // เพิ่มระยะห่าง
                  ],
                ),

                SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, // จัดข้อความให้ชิดซ้าย
            children: [
              Text(
                '*จำเป็นต้องกรอก', // ข้อความเตือน
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: [
                    DropdownMenuItem(
                        value: 'ร้านขายยา',
                        child: Text('ร้านขายยา', style: TextStyle(color: Colors.teal))),
                    DropdownMenuItem(
                        value: 'คลินิก',
                        child: Text('คลินิก', style: TextStyle(color: Colors.teal))),
                    DropdownMenuItem(
                        value: 'สถานีอนามัย',
                        child: Text('สถานีอนามัย', style: TextStyle(color: Colors.teal))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'ประเภทสถานพยาบาล',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    prefixIcon: Icon(Icons.category, color: Colors.teal),
                  ),
                ),
                ],
          ),
                SizedBox(height: 15),

                // ✅ **ช่องกรอก "รายละเอียดสถานพยาบาล" (แสดงเฉพาะผู้ประกอบการ)**
                if (userRole == 'ผู้ประกอบการสถานพยาบาล' || userRole == 'admin') ...[
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'รายละเอียดสถานพยาบาล',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: Icon(Icons.description, color: Colors.teal),
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: openingHoursController,
                    decoration: InputDecoration(
                      labelText: 'เวลาทำการ (เช่น 08:00 - 18:00)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: Icon(Icons.access_time, color: Colors.teal),
                    ),
                  ),
                  SizedBox(height: 15),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isNotEmpty && _selectedType != null && _selectedPosition != null) {
                          Navigator.of(context).pop();
                          await _saveLocation(
                            name: nameController.text,
                            type: _selectedType!,
                            description: userRole == 'ผู้ประกอบการสถานพยาบาล' || userRole == 'admin'
                                ? descriptionController.text
                                : null, // ถ้าไม่ใช่ผู้ประกอบการจะไม่บันทึก
                            openingHours: userRole == 'ผู้ประกอบการสถานพยาบาล' || userRole == 'admin'
                                ? openingHoursController.text
                                : null, // ถ้าไม่ใช่ผู้ประกอบการจะไม่บันทึก
                          );
                        } else {
                          _showAlertInfo(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'บันทึก',
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
      ),
    );
  }


  Future<void> _saveLocation({
    required String name,
    required String type,
    String? description, // ✅ ถ้ามีค่าให้บันทึกลงฐานข้อมูล
    String? openingHours, // ✅ ถ้ามีค่าให้บันทึกลงฐานข้อมูล
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // หาก user เป็น null ให้ return ออกไป

      // ✅ บันทึกข้อมูลลง Firestore
      final docRef = await FirebaseFirestore.instance.collection('locations').add({
        'name': name,
        'type': type,
        'latitude': _selectedPosition!.latitude,
        'longitude': _selectedPosition!.longitude,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        if (description != null) 'description': description, // ✅ บันทึกเฉพาะถ้ามีข้อมูล
        if (openingHours != null) 'openingHours': openingHours, // ✅ บันทึกเฉพาะถ้ามีข้อมูล
      });

      // ✅ สร้างไอคอน Marker สำหรับ Google Maps
      final Uint8List markerIcon = await createCustomMarkerBitmap(name, Colors.blueAccent);
      final marker = Marker(
        markerId: MarkerId(docRef.id),
        position: _selectedPosition!,
        icon: BitmapDescriptor.fromBytes(markerIcon),
        infoWindow: InfoWindow(title: name),
      );

      // ✅ อัปเดต State ของ Marker
      setState(() {
        _markers[MarkerId(docRef.id)] = marker;
      });

      // ✅ แสดง Alert เมื่อบันทึกสำเร็จ
      _showSuccessAlert();

    } catch (e) {
      // ✅ แจ้งเตือนหากเกิดข้อผิดพลาด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }


  void _showSuccessAlert() {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
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
                    'บันทึกสำเร็จ!',
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
                      Navigator.of(context).pop(); // ปิด Alert
                      Navigator.of(context).pop();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
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


  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _showAdminAddLocationDialog() {
    List<Map<String, dynamic>> locations = []; // เก็บข้อมูลสถานที่ที่เพิ่ม

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final openingHoursController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();
    String? selectedType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'เพิ่มสถานที่ (Admin)',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'ชื่อสถานที่',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: Icon(Icons.edit_location_alt, color: Colors.teal),
                    ),
                  ),
                  SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: [
                      DropdownMenuItem(value: 'ร้านขายยา', child: Text('ร้านขายยา')),
                      DropdownMenuItem(value: 'คลินิก', child: Text('คลินิก')),
                      DropdownMenuItem(value: 'สถานีอนามัย', child: Text('สถานีอนามัย')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'ประเภทสถานพยาบาล',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: Icon(Icons.category, color: Colors.teal),
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'รายละเอียดสถานพยาบาล',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: Icon(Icons.description, color: Colors.teal),
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: openingHoursController,
                    decoration: InputDecoration(
                      labelText: 'เวลาทำการ (เช่น 08:00 - 18:00)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: Icon(Icons.access_time, color: Colors.teal),
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: latitudeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ละติจูด',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: Icon(Icons.map, color: Colors.teal),
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: longitudeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ลองจิจูด',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: Icon(Icons.map, color: Colors.teal),
                    ),
                  ),
                  SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty &&
                              selectedType != null &&
                              latitudeController.text.isNotEmpty &&
                              longitudeController.text.isNotEmpty) {
                            setState(() {
                              locations.add({
                                'name': nameController.text,
                                'type': selectedType,
                                'description': descriptionController.text,
                                'openingHours': openingHoursController.text,
                                'latitude': double.parse(latitudeController.text),
                                'longitude': double.parse(longitudeController.text),
                              });

                              nameController.clear();
                              descriptionController.clear();
                              openingHoursController.clear();
                              latitudeController.clear();
                              longitudeController.clear();
                              selectedType = null;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text('+ เพิ่มสถานที่', style: TextStyle(color: Colors.white)),
                      ),

                      ElevatedButton(
                        onPressed: () async {
                          if (locations.isNotEmpty) {
                            await _saveMultipleLocations(locations);
                            Navigator.of(context).pop();
                            _showSuccessAlert();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text('บันทึกทั้งหมด', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveMultipleLocations(List<Map<String, dynamic>> locations) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      for (var location in locations) {
        await FirebaseFirestore.instance.collection('locations').add({
          'name': location['name'],
          'type': location['type'],
          'description': location['description'],
          'openingHours': location['openingHours'],
          'latitude': location['latitude'],
          'longitude': location['longitude'],
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      _showSuccessAlert();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ปักหมุดสถานที่',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
            letterSpacing: 1.5,
            decoration: TextDecoration.underline,
            decorationColor: Colors.tealAccent,
            decorationThickness: 2,
          ),
        ),
        backgroundColor: Colors.teal,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get()
                : Future.value(null),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return SizedBox(); // ✅ ไม่แสดงอะไรเลยหากไม่มีข้อมูล
              final userRole = snapshot.data!['role'] ?? '';

              return userRole == 'admin'
                  ? IconButton(
                icon: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.add_location_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                onPressed: _showAdminAddLocationDialog,
                tooltip: 'เพิ่มสถานที่ (Admin เท่านั้น)',
              )
                  : SizedBox(); // ✅ ถ้าไม่ใช่ admin ให้คืนค่าเป็น SizedBox() เพื่อซ่อนปุ่ม
            },
          ),

          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_currentMapType == MapType.normal ? Colors.blue : Colors.teal, Colors.tealAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(8),
              child: Icon(
                _currentMapType == MapType.normal ? Icons.satellite : Icons.map,
                color: Colors.white,
                size: 28,
              ),
            ),
            onPressed: _toggleMapType,
            tooltip: _currentMapType == MapType.normal ? 'เปลี่ยนไปแผนที่ดาวเทียม' : 'เปลี่ยนไปแผนที่ปกติ',
          ),
        ],
      ),

      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            initialCameraPosition: _currentPosition != null
                ? CameraPosition(target: _currentPosition!, zoom: 16)
                : CameraPosition(
                target: LatLng(13.736717, 100.523186), zoom: 5),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: Set<Marker>.of(_markers.values)
              ..add(
                Marker(
                  markerId: MarkerId("selected_marker"),
                  position: _selectedPosition ?? LatLng(0, 0),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                  draggable: false,
                ),
              ),
            onTap: (LatLng position) {
              setState(() {
                _selectedPosition = position;
                _markers[MarkerId("selected_marker")] = Marker(
                  markerId: MarkerId("selected_marker"),
                  position: position,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                  infoWindow: InfoWindow(title: "ตำแหน่งที่เลือก"),
                );
              });
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  _currentMapType == MapType.normal
                      ? 'แผนที่ปกติ'
                      : 'แผนที่ดาวเทียม',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSaveLocationDialog,
        label: Text(
          'บันทึกตำแหน่ง',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
            letterSpacing: 1.2,
          ),
        ),

        icon: Icon(
          Icons.save,
          color: Colors.white,
        ),
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}