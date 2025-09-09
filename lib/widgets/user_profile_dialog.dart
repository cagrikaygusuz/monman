import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_state_provider.dart';

class UserProfileDialog extends StatefulWidget {
  final UserProfile? userProfile;

  const UserProfileDialog({super.key, this.userProfile});

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.userProfile != null) {
      _nameController.text = widget.userProfile!.name;
      _emailController.text = widget.userProfile!.email;
      _phoneController.text = widget.userProfile!.phone ?? '';
      _occupationController.text = widget.userProfile!.occupation ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.userProfile != null;
    final isTurkish = context.watch<AppStateProvider>().selectedLanguage == 'Turkish';

    return AlertDialog(
      title: Text(isEditing 
        ? (isTurkish ? 'Profili Düzenle' : 'Edit Profile')
        : (isTurkish ? 'Profil Oluştur' : 'Create Profile')
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar Section
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: widget.userProfile?.avatarPath != null 
                  ? ClipOval(
                      child: Image.asset(
                        widget.userProfile!.avatarPath!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement avatar selection
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isTurkish 
                        ? 'Avatar seçimi yakında gelecek' 
                        : 'Avatar selection coming soon'
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: Text(isTurkish ? 'Fotoğraf Seç' : 'Select Photo'),
              ),
              const SizedBox(height: 16),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isTurkish ? 'Ad Soyad' : 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isTurkish ? 'Ad Soyad gerekli' : 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: isTurkish ? 'E-posta' : 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isTurkish ? 'E-posta gerekli' : 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return isTurkish ? 'Geçerli bir e-posta girin' : 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isTurkish ? 'Telefon' : 'Phone',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Occupation Field
              TextFormField(
                controller: _occupationController,
                decoration: InputDecoration(
                  labelText: isTurkish ? 'Meslek' : 'Occupation',
                  prefixIcon: const Icon(Icons.work_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isTurkish ? 'İptal' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          child: Text(isEditing 
            ? (isTurkish ? 'Güncelle' : 'Update')
            : (isTurkish ? 'Kaydet' : 'Save')
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return; // Prevent multiple submissions
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      final appState = context.read<AppStateProvider>();
      
      final profile = widget.userProfile?.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        occupation: _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        updatedAt: now,
      ) ?? UserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        occupation: _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      
      if (widget.userProfile != null) {
        await appState.updateUserProfile(profile);
      } else {
        await appState.createUserProfile(profile);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AppStateProvider>().selectedLanguage == 'Turkish'
              ? 'Profil kaydedilirken bir hata oluştu'
              : 'Error saving profile'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}