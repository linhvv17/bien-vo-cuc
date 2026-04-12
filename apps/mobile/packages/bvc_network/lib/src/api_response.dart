class ApiResponse<T> {
  ApiResponse({
    required this.success,
    required this.data,
    required this.message,
    required this.meta,
  });

  final bool success;
  final T data;
  final String message;
  final Map<String, dynamic> meta;
}

ApiResponse<T> parseApiResponse<T>(
  Map<String, dynamic> json,
  T Function(dynamic data) parseData,
) {
  final success = json['success'] == true;
  final message = (json['message'] as String?) ?? '';
  final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

  if (!success) {
    throw Exception(message.isNotEmpty ? message : 'Request failed');
  }

  return ApiResponse<T>(
    success: true,
    data: parseData(json['data']),
    message: message,
    meta: meta,
  );
}

