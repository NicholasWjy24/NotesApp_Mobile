# 📝 NNotes - Smart Note Organization App

A powerful Flutter-based note-taking application with advanced folder organization and hierarchical structure management.

## 🎯 Overview

NNotes is a feature-rich note-taking app that allows users to create, organize, and manage notes within a flexible folder hierarchy system. The app provides an intuitive interface for organizing notes into folders and subfolders, making it easy to maintain a structured approach to note-taking.

## ✨ Key Features

### 📁 **Hierarchical Folder System**
- **Root Folders**: Create main folders at the top level
- **Subfolders**: Organize content by creating folders within folders
- **Nested Structure**: Unlimited depth for complex organization
- **Visual Hierarchy**: Clear indentation and folder icons show the structure

### 📝 **Smart Note Management**
- **Rich Text Editing**: Create notes with formatted content using Quill editor
- **Auto-save**: Notes are automatically saved as you type
- **Folder Assignment**: Assign notes to specific folders or leave them unassigned
- **Quick Organization**: Drag-and-drop-like functionality for moving notes between folders

### 🔄 **Intuitive Navigation**
- **Side Drawer**: Easy access to all folders and notes
- **Breadcrumb Navigation**: See your current location in the folder hierarchy
- **Back Button**: Navigate up the folder structure with ease
- **Quick Actions**: Context menus for folder and note operations

### 🎨 **User Experience**
- **Modern UI**: Clean, Material Design interface
- **Visual Feedback**: Different card styles for folders vs notes
- **Smart Filtering**: View notes by folder or see all unassigned notes
- **Real-time Updates**: Changes reflect immediately across the app

## 🚀 How It Works

### **Creating and Organizing Notes**

1. **Add Notes**: Use the floating action button (+) to create new notes
2. **Folder Assignment**: 
   - Create notes directly in a selected folder
   - Move existing notes to folders using the context menu
   - Leave notes unassigned for later organization

### **Folder Management**

1. **Create Folders**: Add new folders at any level
2. **Subfolder Creation**: Create folders within existing folders
3. **Move Folders**: 
   - Move folders to root level
   - Move folders into other folders
   - Prevent circular references automatically

### **Smart Organization Features**

#### **Automatic Addition**
- When inside a folder, clicking on other folders/notes automatically adds them to the current folder
- Subfolders always navigate when clicked (they don't get added)
- Visual indicators show which items can be added

#### **Note Counting**
- Each folder displays the total number of notes (including subfolders)
- Subfolder count is shown for better organization awareness

#### **Folder Path Display**
- Notes show their complete folder path (e.g., "Work > Projects > Meeting Notes")
- App bar displays current location in the folder hierarchy

## 🏗️ Technical Architecture

### **Clean Code Structure**
```
lib/
├── services/           # Business logic and data operations
│   ├── folder_service.dart
│   └── note_service.dart
├── widgets/            # Reusable UI components
│   ├── folder_card.dart
│   ├── note_card.dart
│   └── app_drawer.dart
├── data/              # Data models
│   ├── folder_data.dart
│   └── note_data.dart
└── screen/            # Main application screens
    └── home/
        └── home_screen.dart
```

### **Data Persistence**
- **LocalStore**: Local database for storing notes and folders
- **Real-time Updates**: Stream-based data synchronization
- **Offline Support**: All data stored locally on device

### **State Management**
- **StatefulWidget**: Efficient state management for UI updates
- **Stream Subscriptions**: Real-time data listening
- **Service Layer**: Clean separation of business logic

## 📱 User Flow

### **Creating Your First Note**
1. Open the app
2. Tap the + button
3. Select "Add Note"
4. Write your note content
5. Save automatically

### **Organizing with Folders**
1. Open the side drawer
2. Use the context menu on any folder
3. Select "Add Subfolder"
4. Name your new subfolder
5. Start organizing notes within it

### **Moving Content**
1. Navigate to a folder
2. Click on notes or folders from other locations
3. They automatically move to the current folder
4. Use the back button to navigate up the hierarchy

## 🎨 Design Principles

- **Intuitive Navigation**: Easy-to-understand folder structure
- **Visual Hierarchy**: Clear distinction between folders and notes
- **Responsive Design**: Works seamlessly across different screen sizes
- **Accessibility**: Proper contrast and touch targets

## 🔧 Development

### **Prerequisites**
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code

### **Getting Started**
```bash
# Clone the repository
git clone [repository-url]

# Navigate to project directory
cd nnotes

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### **Key Dependencies**
- `flutter_quill`: Rich text editing
- `localstore`: Local data persistence
- `intl`: Date formatting and localization

## 🚀 Future Enhancements

- **Cloud Sync**: Synchronize notes across devices
- **Search Functionality**: Find notes and folders quickly
- **Tags System**: Additional organization with tags
- **Export Options**: Share notes in various formats
- **Dark Mode**: Enhanced visual experience
- **Collaboration**: Share folders with other users

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**NNotes** - Organize your thoughts, one folder at a time! 📝✨
