import 'dart:collection';

/// Rate limiting utility for social features
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  // Storage for rate limit tracking
  final Map<String, Queue<DateTime>> _requestHistory = {};
  final Map<String, DateTime> _lastRequestTime = {};

  /// Checks if an operation is allowed based on rate limits
  bool isAllowed({
    required String userId,
    required String operation,
    required int maxRequests,
    required Duration timeWindow,
  }) {
    final key = '${userId}_$operation';
    final now = DateTime.now();
    
    // Get or create request history for this key
    final history = _requestHistory.putIfAbsent(key, () => Queue<DateTime>());
    
    // Remove old requests outside the time window
    final cutoffTime = now.subtract(timeWindow);
    while (history.isNotEmpty && history.first.isBefore(cutoffTime)) {
      history.removeFirst();
    }
    
    // Check if we're within the limit
    if (history.length >= maxRequests) {
      return false;
    }
    
    return true;
  }

  /// Records a request for rate limiting
  void recordRequest({
    required String userId,
    required String operation,
  }) {
    final key = '${userId}_$operation';
    final now = DateTime.now();
    
    // Add to history
    final history = _requestHistory.putIfAbsent(key, () => Queue<DateTime>());
    history.add(now);
    
    // Update last request time
    _lastRequestTime[key] = now;
  }

  /// Gets the time until the next request is allowed
  Duration? getTimeUntilNextAllowed({
    required String userId,
    required String operation,
    required int maxRequests,
    required Duration timeWindow,
  }) {
    final key = '${userId}_$operation';
    final history = _requestHistory[key];
    
    if (history == null || history.length < maxRequests) {
      return null; // Request is allowed now
    }
    
    // Find the oldest request that's still within the time window
    final now = DateTime.now();
    final cutoffTime = now.subtract(timeWindow);
    
    DateTime? oldestRelevantRequest;
    for (final requestTime in history) {
      if (requestTime.isAfter(cutoffTime)) {
        oldestRelevantRequest = requestTime;
        break;
      }
    }
    
    if (oldestRelevantRequest == null) {
      return null; // All requests are old, new request is allowed
    }
    
    // Calculate when the oldest request will expire
    final expiryTime = oldestRelevantRequest.add(timeWindow);
    if (expiryTime.isAfter(now)) {
      return expiryTime.difference(now);
    }
    
    return null;
  }

  /// Gets the number of requests made in the current time window
  int getRequestCount({
    required String userId,
    required String operation,
    required Duration timeWindow,
  }) {
    final key = '${userId}_$operation';
    final history = _requestHistory[key];
    
    if (history == null) {
      return 0;
    }
    
    final now = DateTime.now();
    final cutoffTime = now.subtract(timeWindow);
    
    return history.where((time) => time.isAfter(cutoffTime)).length;
  }

  /// Checks if minimum time has passed since last request
  bool hasMinimumTimePassed({
    required String userId,
    required String operation,
    required Duration minimumInterval,
  }) {
    final key = '${userId}_$operation';
    final lastTime = _lastRequestTime[key];
    
    if (lastTime == null) {
      return true; // No previous request
    }
    
    final now = DateTime.now();
    return now.difference(lastTime) >= minimumInterval;
  }

  /// Clears rate limit history for a specific user and operation
  void clearHistory({
    required String userId,
    required String operation,
  }) {
    final key = '${userId}_$operation';
    _requestHistory.remove(key);
    _lastRequestTime.remove(key);
  }

  /// Clears all rate limit history for a user
  void clearUserHistory(String userId) {
    final keysToRemove = <String>[];
    
    for (final key in _requestHistory.keys) {
      if (key.startsWith('${userId}_')) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _requestHistory.remove(key);
      _lastRequestTime.remove(key);
    }
  }

  /// Cleans up old entries to prevent memory leaks
  void cleanup() {
    final now = DateTime.now();
    final maxAge = const Duration(hours: 24); // Keep history for 24 hours max
    final cutoffTime = now.subtract(maxAge);
    
    final keysToRemove = <String>[];
    
    for (final entry in _requestHistory.entries) {
      final history = entry.value;
      
      // Remove old requests
      while (history.isNotEmpty && history.first.isBefore(cutoffTime)) {
        history.removeFirst();
      }
      
      // If no recent requests, remove the entire entry
      if (history.isEmpty) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _requestHistory.remove(key);
      _lastRequestTime.remove(key);
    }
  }
}

/// Specific rate limiters for different social operations
class SocialRateLimiters {
  static final RateLimiter _rateLimiter = RateLimiter();

  // Rate limit configurations
  static const Duration _dailyWindow = Duration(days: 1);
  static const Duration _hourlyWindow = Duration(hours: 1);
  static const Duration _minuteWindow = Duration(minutes: 1);
  static const Duration _minimumInterval = Duration(minutes: 1);

  /// Friend request rate limiter
  static bool canSendFriendRequest(String userId) {
    return _rateLimiter.isAllowed(
      userId: userId,
      operation: 'friend_request',
      maxRequests: 10, // 10 per day
      timeWindow: _dailyWindow,
    );
  }

  static void recordFriendRequest(String userId) {
    _rateLimiter.recordRequest(userId: userId, operation: 'friend_request');
  }

  static Duration? getTimeUntilNextFriendRequest(String userId) {
    return _rateLimiter.getTimeUntilNextAllowed(
      userId: userId,
      operation: 'friend_request',
      maxRequests: 10,
      timeWindow: _dailyWindow,
    );
  }

  static int getFriendRequestCount(String userId) {
    return _rateLimiter.getRequestCount(
      userId: userId,
      operation: 'friend_request',
      timeWindow: _dailyWindow,
    );
  }

  /// Username search rate limiter
  static bool canSearchUsers(String userId) {
    return _rateLimiter.isAllowed(
      userId: userId,
      operation: 'user_search',
      maxRequests: 20, // 20 per minute
      timeWindow: _minuteWindow,
    );
  }

  static void recordUserSearch(String userId) {
    _rateLimiter.recordRequest(userId: userId, operation: 'user_search');
  }

  static Duration? getTimeUntilNextSearch(String userId) {
    return _rateLimiter.getTimeUntilNextAllowed(
      userId: userId,
      operation: 'user_search',
      maxRequests: 20,
      timeWindow: _minuteWindow,
    );
  }

  /// Scheduled message rate limiter
  static bool canCreateScheduledMessage(String userId) {
    return _rateLimiter.isAllowed(
      userId: userId,
      operation: 'scheduled_message',
      maxRequests: 10, // 10 per hour
      timeWindow: _hourlyWindow,
    ) && _rateLimiter.hasMinimumTimePassed(
      userId: userId,
      operation: 'scheduled_message',
      minimumInterval: _minimumInterval,
    );
  }

  static void recordScheduledMessage(String userId) {
    _rateLimiter.recordRequest(userId: userId, operation: 'scheduled_message');
  }

  static Duration? getTimeUntilNextScheduledMessage(String userId) {
    final rateLimitTime = _rateLimiter.getTimeUntilNextAllowed(
      userId: userId,
      operation: 'scheduled_message',
      maxRequests: 10,
      timeWindow: _hourlyWindow,
    );

    final minimumIntervalTime = _rateLimiter.hasMinimumTimePassed(
      userId: userId,
      operation: 'scheduled_message',
      minimumInterval: _minimumInterval,
    ) ? null : _minimumInterval;

    if (rateLimitTime != null && minimumIntervalTime != null) {
      return rateLimitTime.compareTo(minimumIntervalTime) > 0 
          ? rateLimitTime 
          : minimumIntervalTime;
    }

    return rateLimitTime ?? minimumIntervalTime;
  }

  /// Shared folder operation rate limiter
  static bool canModifySharedFolder(String userId) {
    return _rateLimiter.isAllowed(
      userId: userId,
      operation: 'shared_folder_modify',
      maxRequests: 30, // 30 per hour
      timeWindow: _hourlyWindow,
    );
  }

  static void recordSharedFolderModification(String userId) {
    _rateLimiter.recordRequest(userId: userId, operation: 'shared_folder_modify');
  }

  /// Public folder operation rate limiter
  static bool canModifyPublicFolder(String userId) {
    return _rateLimiter.isAllowed(
      userId: userId,
      operation: 'public_folder_modify',
      maxRequests: 20, // 20 per hour
      timeWindow: _hourlyWindow,
    );
  }

  static void recordPublicFolderModification(String userId) {
    _rateLimiter.recordRequest(userId: userId, operation: 'public_folder_modify');
  }

  /// General cleanup method
  static void cleanup() {
    _rateLimiter.cleanup();
  }

  /// Clear history for a specific user
  static void clearUserHistory(String userId) {
    _rateLimiter.clearUserHistory(userId);
  }
}