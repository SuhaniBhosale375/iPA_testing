import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import './models/visitor_request_model.dart';

class RequestStatusPage extends StatefulWidget {
  final String hostName;
  final String backendIp; // ✅ Keep passing IP from your login page

  const RequestStatusPage({
    Key? key,
    required this.hostName,
    required this.backendIp,
  }) : super(key: key);

  @override
  State<RequestStatusPage> createState() => _RequestStatusPageState();
}

class _RequestStatusPageState extends State<RequestStatusPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<VisitorRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final host = widget.hostName.trim();
    final ip = widget.backendIp.trim();

    if (host.isEmpty || ip.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Missing host name or backend IP!";
      });
      return;
    }

    final apiUrl =
        "http://$ip:5213/api/VisitorRequests/byhost/${Uri.encodeComponent(host)}";
    debugPrint("[StatusPage] Fetching from $apiUrl");

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final filtered = data
            .map((e) => VisitorRequest.fromJson(e))
            .where((r) {
          final status = r.status.trim().toLowerCase();
          return status == 'approved' || status == 'pending' || status == 'rejected';
        }).toList();

        setState(() {
          _requests = filtered;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Server returned ${response.statusCode}";
        });
      }
    } catch (e) {
      debugPrint("[StatusPage] Network error: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Network Error: $e";
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // ✅ Open the dashboard in external browser
  void _openDashboard() async {
    const dashboardUrl = "http://live.testproject.info";
    final Uri url = Uri.parse(dashboardUrl);
    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open dashboard")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening dashboard: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          "Requests - ${widget.hostName}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0E3F89),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: "Open Dashboard",
            onPressed: _openDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Card(
          color: Colors.red[50],
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      )
          : _requests.isEmpty
          ? const Center(
        child: Text(
          "No Approved / Pending / Rejected requests found.",
          style: TextStyle(fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchRequests,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _requests.length,
          itemBuilder: (context, index) {
            final req = _requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor:
                  _getStatusColor(req.status).withOpacity(0.15),
                  child: Icon(
                    _getStatusIcon(req.status),
                    color: _getStatusColor(req.status),
                    size: 28,
                  ),
                ),
                title: Text(
                  req.guest,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Status: ${req.status}",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(req.status)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    req.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(req.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchRequests,
        backgroundColor: const Color(0xFF0E3F89),
        icon: const Icon(Icons.refresh),
        label: const Text("Refresh"),
      ),
    );
  }
}