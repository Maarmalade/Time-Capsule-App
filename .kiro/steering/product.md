---
inclusion: always
---

# Time Capsule - Product Guidelines

Time Capsule is a Flutter-based cross-platform application for creating and sharing digital memories through sophisticated memory albums and diary entries.

## Core Product Features

### Memory Management
- **Digital Memory Albums**: Create, organize, and manage personal memory collections in folders
- **Diary Entries**: Rich diary system with text, audio, images, and video support
- **Media Capture**: Integrated camera, audio recording, and media import capabilities
- **Content Organization**: Hierarchical folder structure with tagging and search

### Social & Sharing
- **Friend System**: Add friends, manage requests, collaborate on shared folders
- **Social Sharing**: Share memory folders with granular privacy controls
- **Public Discovery**: Browse and access publicly shared memory collections
- **Scheduled Messages**: Time-delayed delivery of messages and memories

### Media Handling
- **Multi-format Support**: Photos, videos, audio recordings, and text content
- **Automatic Compression**: Optimize media for storage and performance
- **Responsive Playback**: Adaptive video/audio players with accessibility controls

## User Experience Principles

### Accessibility First
- **WCAG 2.1 AA Compliance**: All features must meet accessibility standards
- **Screen Reader Support**: Comprehensive semantic markup and labels
- **Keyboard Navigation**: Full keyboard accessibility for all interactions
- **High Contrast**: Support for high contrast themes and color customization

### Professional Design
- **Material Design 3**: Follow latest Material Design principles
- **Consistent Typography**: Inter/Roboto font system with proper hierarchy
- **8px Grid System**: Consistent spacing and layout alignment
- **Responsive Design**: Adaptive layouts for mobile, tablet, and desktop

### Performance Standards
- **Fast Load Times**: Optimize for quick app startup and navigation
- **Efficient Media**: Compress and cache media appropriately
- **Offline Capability**: Core features should work without internet
- **Battery Optimization**: Minimize background processing and resource usage

## Development Guidelines

### Feature Implementation
- **User-Centric**: Always consider the user's emotional connection to their memories
- **Privacy-Focused**: Default to private, explicit consent for sharing
- **Intuitive Navigation**: Clear information architecture and user flows
- **Error Prevention**: Validate inputs and provide helpful error messages

### Content Handling
- **Data Preservation**: Never lose user content, implement robust backup
- **Version Control**: Track changes to shared folders and collaborative content
- **Conflict Resolution**: Handle simultaneous edits gracefully
- **Content Moderation**: Basic filtering for public content

### Technical Constraints
- **Cross-Platform**: Maintain feature parity across all supported platforms
- **Firebase Integration**: Leverage Firebase services for backend functionality
- **Real-time Sync**: Use Firestore streams for live updates
- **Scalable Architecture**: Design for growth in users and content volume

## Key User Journeys

1. **Onboarding**: Authentication → Profile setup → First memory creation
2. **Daily Use**: Quick capture → Organize → Share with friends
3. **Collaboration**: Invite friends → Shared folder creation → Collaborative editing
4. **Discovery**: Browse public folders → Save favorites → Engage with community
5. **Reflection**: Review past memories → Create nostalgia reminders → Schedule future messages

## Content Strategy

### Memory Types
- **Personal Moments**: Individual experiences and reflections
- **Shared Experiences**: Group events and collaborative memories
- **Milestone Tracking**: Important life events and achievements
- **Creative Expression**: Artistic content and personal projects

### Engagement Features
- **Nostalgia Reminders**: Surface old memories at meaningful times
- **Memory Prompts**: Suggest content creation based on patterns
- **Social Notifications**: Friend activity and shared folder updates
- **Achievement System**: Celebrate consistent usage and milestones+