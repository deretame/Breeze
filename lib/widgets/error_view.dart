import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            errorMessage,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onRetry, child: const Text('重新加载')),
        ],
      ),
    );
  }
}
