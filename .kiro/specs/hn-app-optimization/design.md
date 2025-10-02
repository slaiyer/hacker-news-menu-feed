# Design Document

## Overview

This design document outlines the architectural improvements and optimizations for the Hacker News menu bar application. The current monolithic ContentView will be refactored into a clean MVVM architecture with proper separation of concerns, optimized networking, intelligent caching, and enhanced performance.

The key design principles are:
- **Performance First**: Sub-3-second load times through concurrent fetching and caching
- **Resource Efficiency**: Memory usage under 50MB with proper lifecycle management
- **Resilient Networking**: Robust error handling with retry logic and offline support
- **Clean Architecture**: MVVM pattern with clear separation of concerns
- **User Experience**: Smooth animations and clear feedback

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Business     │    │      Data       │
│     Layer       │    │     Logic       │    │     Layer       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • ContentView   │◄──►│ • StoryViewModel│◄──►│ • StoryRepository│
│ • Components    │    │ • AppState      │    │ • NetworkService │
│ • Animations    │    │ • Preferences   │    │ • CacheManager  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### MVVM Pattern Implementation

**Model Layer:**
- `Story`: Core data model for Hacker News stories
- `AppPreferences`: User settings and configuration
- `NetworkError`: Comprehensive error types

**View Layer:**
- `ContentView`: Main app entry point
- `StoryListView`: Displays the list of stories
- `ActionBarView`: Controls and settings
- `StoryRowView`: Individual story presentation

**ViewModel Layer:**
- `StoryViewModel`: Manages story data and business logic
- `AppStateManager`: Global app state management
- `PreferencesManager`: User preferences handling

## Components and Interfaces

### 1. Data Layer

#### StoryRepository
```swift
protocol StoryRepositoryProtocol {
    func fetchTopStories(limit: Int) async throws -> [Story]
    func getCachedStories() -> [Story]
    func cacheStories(_ stories: [Story])
    func clearExpiredCache()
}
```

**Responsibilities:**
- Coordinate between network and cache layers
- Implement cache-first strategy with background refresh
- Handle data validation and transformation

#### NetworkService
```swift
protocol NetworkServiceProtocol {
    func fetchTopStoryIds() async throws -> [Int]
    func fetchStory(id: Int) async throws -> StoryFetchResponse
    func fetchStoriesBatch(_ ids: [Int]) async throws -> [StoryFetchResponse]
}
```

**Key Optimizations:**
- Connection pooling with URLSession configuration
- Concurrent request batching (20 stories per batch)
- Request prioritization and cancellation
- Exponential backoff retry logic
- Circuit breaker pattern for failing endpoints

#### CacheManager
```swift
protocol CacheManagerProtocol {
    func store<T: Codable>(_ object: T, forKey key: String, expiration: TimeInterval)
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func isExpired(forKey key: String) -> Bool
    func clearExpired()
    func clearAll()
}
```

**Implementation Details:**
- File-based caching using Documents directory
- JSON encoding/decoding for story data
- Automatic cleanup of expired entries
- Memory usage monitoring with size limits (10MB max)

### 2. Business Logic Layer

#### StoryViewModel
```swift
@MainActor
class StoryViewModel: ObservableObject {
    @Published var stories: [Story] = []
    @Published var isLoading: Bool = false
    @Published var error: NetworkError?
    @Published var lastUpdated: Date?

    func loadStories(forceRefresh: Bool = false) async
    func refreshStories() async
    func cancelCurrentOperation()
}
```

**Key Features:**
- Cache-first loading strategy
- Incremental updates to minimize UI disruption
- Proper error state management
- Background refresh scheduling

#### AppStateManager
```swift
@MainActor
class AppStateManager: ObservableObject {
    @Published var preferences: AppPreferences
    @Published var networkStatus: NetworkStatus
    @Published var appLifecycleState: AppLifecycleState

    func updatePreferences(_ preferences: AppPreferences)
    func handleAppStateChange(_ state: AppLifecycleState)
}
```

### 3. Presentation Layer

#### Optimized UI Components

**StoryListView:**
- LazyVStack for memory efficiency
- Smooth fade animations during updates
- Pull-to-refresh gesture support
- Virtualization for large lists

**StoryRowView:**
- Optimized layout calculations
- Cached text measurements
- Efficient hover state management
- Accessibility support

## Data Models

### Core Models

```swift
struct Story: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let author: String
    let score: Int
    let commentCount: Int
    let url: String?
    let timestamp: Date
    let type: StoryType

    // Computed properties for UI
    var formattedScore: String { ... }
    var formattedCommentCount: String { ... }
    var timeAgo: String { ... }
}

struct AppPreferences: Codable {
    var showHeadlineInMenuBar: Bool = true
    var refreshInterval: TimeInterval = 3600
    var maxStoriesToFetch: Int = 100
    var enableNotifications: Bool = false
    var cacheExpirationTime: TimeInterval = 1800 // 30 minutes
}

enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case rateLimited
    case serverError(Int)
    case decodingError
    case unknown(Error)

    var errorDescription: String? { ... }
    var recoverySuggestion: String? { ... }
}
```

## Error Handling

### Comprehensive Error Strategy

1. **Network Errors:**
   - Automatic retry with exponential backoff
   - Circuit breaker for repeated failures
   - Graceful degradation to cached content

2. **Data Errors:**
   - Validation at model boundaries
   - Sanitization of API responses
   - Fallback to default values

3. **UI Error Feedback:**
   - Non-intrusive error banners
   - Retry action buttons
   - Clear error messages with context

### Error Recovery Patterns

```swift
enum RetryStrategy {
    case exponentialBackoff(maxAttempts: Int)
    case fixedInterval(interval: TimeInterval, maxAttempts: Int)
    case circuitBreaker(failureThreshold: Int, timeout: TimeInterval)
}
```

## Testing Strategy

### Unit Testing
- Repository layer with mocked network responses
- ViewModel business logic validation
- Cache manager functionality
- Error handling scenarios

### Integration Testing
- End-to-end data flow testing
- Network layer with real API responses
- Cache persistence and retrieval
- Performance benchmarking

### Performance Testing
- Memory usage profiling
- Network request timing
- UI responsiveness metrics
- Battery usage monitoring

## Performance Optimizations

### Network Layer Optimizations

1. **Connection Pooling:**
   ```swift
   let configuration = URLSessionConfiguration.default
   configuration.httpMaximumConnectionsPerHost = 6
   configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
   configuration.timeoutIntervalForRequest = 10.0
   ```

2. **Concurrent Fetching Strategy:**
   - Fetch story IDs first (single request)
   - Batch story details into groups of 20
   - Use TaskGroup for concurrent execution
   - Maintain order for consistent UI

3. **Request Prioritization:**
   - High priority for visible stories
   - Background priority for off-screen content
   - Cancellation of unnecessary requests

### Memory Management

1. **Efficient Data Structures:**
   - Use structs for immutable data
   - Implement proper Hashable/Equatable
   - Minimize retained references

2. **Cache Size Management:**
   - LRU eviction policy
   - Automatic cleanup on memory warnings
   - Configurable size limits

3. **UI Optimizations:**
   - LazyVStack for large lists
   - Image caching with size limits
   - Proper view lifecycle management

### Caching Strategy

1. **Multi-Level Caching:**
   - Memory cache for immediate access
   - Disk cache for persistence
   - HTTP cache for network efficiency

2. **Cache Invalidation:**
   - Time-based expiration (30 minutes)
   - Manual refresh capability
   - Background refresh scheduling

3. **Offline Support:**
   - Graceful degradation to cached content
   - Clear offline indicators
   - Automatic sync when online

## Implementation Phases

### Phase 1: Architecture Foundation
- Implement MVVM structure
- Create repository pattern
- Set up dependency injection

### Phase 2: Network Optimization
- Implement optimized network layer
- Add retry logic and error handling
- Create connection pooling

### Phase 3: Caching System
- Implement multi-level caching
- Add cache management
- Create offline support

### Phase 4: UI Enhancements
- Optimize view performance
- Add smooth animations
- Improve user feedback

### Phase 5: Testing and Polish
- Comprehensive test coverage
- Performance optimization
- Bug fixes and refinements
