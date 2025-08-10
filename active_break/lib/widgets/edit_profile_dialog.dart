import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_localizations.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  String? _selectedGender;
  DateTime? _selectedBirthday;
  bool _isLoading = false;

  String? _avatarPath; // persisted path
  XFile? _pickedImage; // temp picked image
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    _usernameController = TextEditingController(text: user?.username ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedGender = user?.gender;
    _selectedBirthday = user?.birthday;
    _avatarPath = user?.avatarUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthday ?? DateTime(now.year - 20, now.month, now.day);
    final firstDate = DateTime(1900);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _chooseAvatar() async {
    try {
      XFile? image;
      // On desktop/web, use file_selector; on mobile, use image_picker
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        final typeGroup = const fs.XTypeGroup(
          label: 'images',
          extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic'],
        );
        final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
        if (file != null) {
          image = XFile(file.path);
        }
      } else {
        image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          imageQuality: 85,
        );
      }

      if (image == null) return;
      setState(() {
        _pickedImage = image;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).translate('error')}: $e')),
      );
    }
  }

  Future<String?> _persistPickedImage(XFile image, int? userId) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory(p.join(docsDir.path, 'avatars'));
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }
      final ext = p.extension(image.path);
      final fileName = userId != null ? 'user_${userId}_${DateTime.now().millisecondsSinceEpoch}$ext' :
        'user_${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetPath = p.join(avatarsDir.path, fileName);
      await File(image.path).copy(targetPath);
      return targetPath;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      String? avatarToSave = _avatarPath;
      if (_pickedImage != null) {
        avatarToSave = await _persistPickedImage(_pickedImage!, userProvider.currentUser?.userId);
      }
      
      final success = await userProvider.updateProfile(
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        gender: _selectedGender,
        birthday: _selectedBirthday,
        avatarUrl: avatarToSave,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('profile_updated')),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('profile_update_failed')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  ImageProvider? _buildAvatarProvider() {
    if (_pickedImage != null) {
      return FileImage(File(_pickedImage!.path));
    }
    if (_avatarPath == null) return null;
    if (_avatarPath!.startsWith('http')) {
      return NetworkImage(_avatarPath!);
    }
    final file = File(_avatarPath!);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).translate('edit_profile')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar picker
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _buildAvatarProvider(),
                      child: _buildAvatarProvider() == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _chooseAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Username as Nickname field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('nickname'),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).translate('field_required');
                  }
                  if (value.length < 3) {
                    return AppLocalizations.of(context).translate('username_too_short');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '${AppLocalizations.of(context).translate('phone')} (${AppLocalizations.of(context).translate('optional')})',
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Gender dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: '${AppLocalizations.of(context).translate('gender')} (${AppLocalizations.of(context).translate('optional')})',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(AppLocalizations.of(context).translate('male')),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(AppLocalizations.of(context).translate('female')),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Birthday picker
              InkWell(
                onTap: _pickBirthday,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context).translate('birthday')}${' (' + AppLocalizations.of(context).translate('optional') + ')'}',
                    prefixIcon: const Icon(Icons.cake_outlined),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedBirthday == null
                            ? '--'
                            : '${_selectedBirthday!.year}-${_selectedBirthday!.month.toString().padLeft(2, '0')}-${_selectedBirthday!.day.toString().padLeft(2, '0')}',
                      ),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context).translate('save')),
        ),
      ],
    );
  }
}
