class ApiConfig {
  // Set this to your Railway URL for production, e.g., 'https://your-app.up.railway.app'
  static const String baseUrl = 'http://localhost:8000';
  
  // Helper for HTTP endpoints
  static String get httpBaseUrl => baseUrl;
  
  // Helper for WebSocket endpoints
  static String get wsBaseUrl {
    if (baseUrl.startsWith('https')) {
      return baseUrl.replaceFirst('https', 'wss');
    } else {
      return baseUrl.replaceFirst('http', 'ws');
    }
  }
}
