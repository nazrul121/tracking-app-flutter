import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IncomingRequestDialog extends StatefulWidget {
  final requestData;

  final VoidCallback onAccept;
  final VoidCallback onIgnore;

  const IncomingRequestDialog({
    super.key,
    required this.requestData,

    required this.onAccept,
    required this.onIgnore,
  });

  @override
  State<IncomingRequestDialog> createState() => _ServiceRequestCardState();
}

class _ServiceRequestCardState extends State<IncomingRequestDialog> {
  Map<String, dynamic>? customerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomerData();
  }

  Future<void> fetchCustomerData() async {
    try {
      final doc = await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.requestData['customer_id'].toString())
        .get();
      if (doc.exists) {
        setState(() {
          customerData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching customer: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> feedback2customer(String status) async {
    try {
      final String customerId = widget.requestData['customer_id'].toString();

      await FirebaseFirestore.instance.collection('request_feedbacks').add({
        'customer_id': customerId,
        'provider_id': widget.requestData['provider_id'],
        'service_id': widget.requestData['service_id'],
        'service_name': widget.requestData['service_name'],
        'timestamp': Timestamp.now(),
        'status': status,
        'seen': false,
      });

      print('Feedback sent to customer');
    } catch (e) {
      print('Failed to send feedback: $e');
    }
  }




  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 1.0,
        heightFactor: 0.4,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(width: 8, color: Colors.red.withValues(alpha: 0.6)),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Material(
            color: Colors.white.withValues(alpha: 0.9),
            elevation: 12,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 25, left: 15, right: 15),
              child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text( 'New Service Request',
                      style: TextStyle( fontSize: 22, fontWeight: FontWeight.bold, ),
                    ),
                  ),
                  Divider(color: Colors.blueGrey.withValues(alpha: 0.2),height: 10,),
                  SizedBox(height: 7),

                  Text(widget.requestData['service_name'], style: TextStyle(fontSize: 20),),
                  if (customerData != null) ...[
                    Text('Customer: ${customerData!['name'] ?? 'N/A'}'),
                    Text('Phone: ${customerData!['phone'] ?? 'N/A'}'),
                    Text('Address: ${customerData!['address'] ?? 'N/A'}'),
                  ],
                  RichText(text: TextSpan(
                    children: [
                      TextSpan(text: 'Distance: ', style: TextStyle(color:Colors.black)),
                      TextSpan(text: double.parse(widget.requestData['distance'].toString()).toStringAsFixed(2), style: TextStyle(color:Colors.black, fontWeight: FontWeight.bold)),
                      TextSpan(text: ' km', style: TextStyle(color:Colors.black)),
                    ]
                  )),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(Colors.grey.withValues(alpha: 0.2)),
                        ),
                        onPressed: () async {
                          await feedback2customer('ignored');
                          widget.onIgnore();
                        },
                        child:  Text('Ignore', style: TextStyle(color: Colors.black45)),
                      ),
                      ElevatedButton.icon(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(Colors.green.withValues(alpha: 0.8)),
                        ),
                        onPressed: () async {
                          await feedback2customer('accepted');
                          widget.onAccept();
                        },
                        label: Text('Accept', style: TextStyle(color: Colors.white)),
                        icon: Icon(Icons.check, color: Colors.white),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
