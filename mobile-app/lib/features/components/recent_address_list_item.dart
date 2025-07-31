import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class RecentAddressListItem extends StatefulWidget {
  final String address;
  final VoidCallback onTap;

  const RecentAddressListItem({
    super.key,
    required this.address,
    required this.onTap,
  });

  @override
  State<RecentAddressListItem> createState() => _RecentAddressListItemState();
}

class _RecentAddressListItemState extends State<RecentAddressListItem> {
  late Future<String> _humanReadableNameFuture;

  @override
  void initState() {
    super.initState();
    _humanReadableNameFuture = HumanReadableChecksumService()
        .getHumanReadableName(widget.address);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).isTablet;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<String>(
            future: _humanReadableNameFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text(
                  'Loading name...',
                  style: TextStyle(
                    color: const Color(0xFF16CECE),
                    fontSize: isTablet ? 18 : 14,
                    fontFamily: 'Fira Code',
                    fontWeight: FontWeight.w400,
                  ),
                );
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return Text(
                  'Unknown Name',
                  style: TextStyle(
                    color: const Color(0xFF16CECE),
                    fontSize: isTablet ? 18 : 14,
                    fontFamily: 'Fira Code',
                    fontWeight: FontWeight.w400,
                  ),
                );
              }
              return Text(
                snapshot.data!,
                style: TextStyle(
                  color: const Color(0xFF16CECE),
                  fontSize: isTablet ? 18 : 14,
                  fontFamily: 'Fira Code',
                  fontWeight: FontWeight.w400,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            widget.address,
            style: TextStyle(
              color: Colors.white.useOpacity(0.60),
              fontSize: isTablet ? 16 : 11,
              fontFamily: 'Fira Code',
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
