---
inclusion: always
---

---
inclusion: always
---

# Time Capsule - Product & UX Guidelines

Time Capsule is a Flutter cross-platform app for creating and sharing digital memories through memory albums and diary entries with rich media support.

## Core Feature Domains

### Memory Management
- **Memory Albums**: Hierarchical folder system for organizing personal collections
- **Diary Entries**: Rich text + multimedia diary with audio/video/image support
- **Media Capture**: Integrated camera, audio recording, and media import
- **Content Search**: Tag-based organization and full-text search capabilities

### Social Features
- **Friend System**: Friend requests, management, and collaboration workflows
- **Shared Folders**: Collaborative memory albums with permission controls
- **Public Discovery**: Browse community-shared memory collections
- **Scheduled Messages**: Time-delayed message delivery system

### Media Processing
- **Multi-format Support**: Photos, videos, audio recordings, text content
- **Automatic Compression**: All media must be compressed before Firebase upload
- **Responsive Players**: Accessible video/audio players with proper controls

## UX Design Principles

### Accessibility Requirements (WCAG 2.1 AA)
- Every interactive element needs `semanticsLabel` and proper roles
- Use design system colors that meet contrast requirements
- Implement keyboard navigation for all features
- Test with screen readers and accessibility tools

### Material Design 3 Standards
- Use `AppColors`, `AppTypography`, `AppSpacing` from design system
- Follow 8px grid system for consistent spacing
- Implement responsive layouts for mobile/tablet/desktop
- Use proper elevation and surface colors

### Performance Guidelines
- Compress all media before upload using `flutter_image_compress`
- Use `ListView.builder` for lists with >20 items
- Implement proper image caching with `cached_network_image`
- Show upload progress for all media operations

## Development Conventions

### User Flow Patterns
- **Authentication Required**: Always check `FirebaseAuth.instance.currentUser` before operations
- **Privacy First**: Default to private content, explicit consent for sharing
- **Error Recovery**: Provide fallback UI when operations fail
- **Loading States**: Show progress indicators for async operations

### Content Handling Rules
- **Data Preservation**: Never lose user content, implement robust error handling
- **Real-time Sync**: Use Firestore streams for live updates
- **Offline Support**: Cache critical data for offline access
- **Conflict Resolution**: Handle simultaneous edits in shared folders

### Navigation Patterns
- Use named routes defined in `routes.dart`
- Implement proper back navigation and breadcrumbs
- Maintain navigation state across platform switches
- Use bottom navigation for primary features, drawer for secondary

## Feature-Specific Guidelines

### Diary System
- Support rich text formatting with multimedia attachments
- Auto-save drafts every 30 seconds
- Implement mood tracking and reflection prompts
- Enable voice-to-text for accessibility

### Memory Albums
- Folder hierarchy with drag-and-drop organization
- Batch operations for multiple items
- Timeline view for chronological browsing
- Export capabilities for data portability

### Social Features
- Friend request notifications with proper badges
- Granular sharing permissions (view/edit/admin)
- Activity feeds for shared folder updates
- Privacy controls for all social interactions

### Scheduled Messages
- Calendar integration for delivery scheduling
- Preview functionality before scheduling
- Cancellation/editing capabilities before delivery
- Notification system for sent messages

## Error Handling Strategy

### User-Facing Errors
- Show contextual error messages, not technical details
- Provide actionable recovery steps when possible
- Use snackbars for temporary errors, dialogs for critical issues
- Implement retry mechanisms for network failures

### Data Validation
- Validate all user inputs before Firebase operations
- Check file sizes and formats before upload
- Sanitize text content for security
- Implement rate limiting for API calls

## Content Guidelines

### Memory Content
- Support personal reflections and milestone tracking
- Enable collaborative storytelling in shared folders
- Implement content tagging for organization
- Provide memory prompts and creative suggestions

### Social Interactions
- Encourage positive community engagement
- Implement basic content moderation for public folders
- Support commenting and reactions on shared content
- Enable memory collaboration workflows

## Platform Considerations

### Cross-Platform Consistency
- Maintain feature parity across Android, iOS, Web, Desktop
- Adapt UI patterns to platform conventions
- Handle platform-specific permissions properly
- Test thoroughly on all target platforms

### Performance Optimization
- Optimize for mobile-first, enhance for larger screens
- Implement lazy loading for media-heavy content
- Use efficient data structures for large collections
- Monitor memory usage in media processing features