import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'request_status_page.dart';
import './models/visitor_request_model.dart';

class RequestFormPage extends StatefulWidget {
  const RequestFormPage({Key? key}) : super(key: key);

  @override
  State<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _guestController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _accessoriesController = TextEditingController();

  final List<String> visitCategories = [
    "Candidate Entry",
    "Customer",
    "Supply",
    "Employee"
  ];
  String? selectedCategory;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _guestController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _hostController.dispose();
    _cardController.dispose();
    _purposeController.dispose();
    _accessoriesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      _timeController.text = pickedTime.format(context);
    }
  }

  void _clearFields() {
    _dateController.clear();
    _timeController.clear();
    _guestController.clear();
    _companyController.clear();
    _addressController.clear();
    _mobileController.clear();
    _emailController.clear();
    _hostController.clear();
    _cardController.clear();
    _purposeController.clear();
    _accessoriesController.clear();
    selectedCategory = null;
  }

  void _showSuccessPopup(String message, String hostName, String backendIp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green,
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 15),
              Text(
                message,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestStatusPage(
                        hostName: hostName,
                        backendIp: backendIp, // ✅ Passing IP here
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.red,
                child: const Icon(Icons.close, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 15),
              Text(
                message,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> submitVisitorRequest() async {
    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final lastIp = prefs.getString('lastBackendIp');

    if (lastIp == null) {
      _showErrorPopup("Backend IP not found. Please login first.");
      setState(() => _isSubmitting = false);
      return false;
    }

    final String baseUrl = "http://$lastIp:5213/api/VisitorRequests";
    final url = Uri.parse(baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "date": _dateController.text.trim(),
          "time": _timeController.text.trim(),
          "guest": _guestController.text.trim(),
          "company": _companyController.text.trim(),
          "address": _addressController.text.trim(),
          "category": selectedCategory ?? "",
          "mobile": _mobileController.text.trim(),
          "email": _emailController.text.trim(),
          "host": _hostController.text.trim(),
          "card": _cardController.text.trim(),
          "purpose": _purposeController.text.trim(),
          "accessories": _accessoriesController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _showSuccessPopup("Visitor request submitted successfully!",
            _hostController.text.trim(), lastIp);
        return true;
      } else {
        _showErrorPopup("API Error ${response.statusCode}: ${response.body}");
        return false;
      }
    } catch (e) {
      _showErrorPopup("Network Error: $e");
      return false;
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await submitVisitorRequest();
    }
  }

  String? emailValidator(String? val) {
    if (val == null || val.trim().isEmpty) return "Required";
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(val.trim())) return "Invalid email";
    return null;
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hint, {
        TextInputType? keyboardType,
        String? Function(String?)? validator,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black12),
          ),
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  height: 70,
                  margin: const EdgeInsets.only(bottom: 24, top: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E3F89),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Visitor Request Form",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                _buildTextField(_mobileController, "Mobile Number",
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return "Required";
                      if (val.trim().length != 10)
                        return "Enter valid 10-digit number";
                      return null;
                    }),
                _buildTextField(_emailController, "Email ID",
                    keyboardType: TextInputType.emailAddress,
                    validator: emailValidator),
                _buildTextField(_dateController, "Select Date",
                    readOnly: true,
                    onTap: _pickDate,
                    validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null),
                _buildTextField(_timeController, "Select Time",
                    readOnly: true,
                    onTap: _pickTime,
                    validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null),
                _buildTextField(_guestController, "Guest Name",
                    validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null),
                _buildTextField(_companyController, "Company Name",
                    validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null),
                _buildTextField(_addressController, "Address",
                    validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: visitCategories
                      .map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedCategory = val),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Select Visit Category",
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? "Required" : null,
                ),
                _buildTextField(_hostController, "Host Name",
                    validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null),
                _buildTextField(_cardController, "Card Name",
                    validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null),
                _buildTextField(_purposeController, "Visit Purpose",
                    validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null),
                _buildTextField(_accessoriesController, "Accessories Carrying",
                    validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E3F89),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Submit Request",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
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
