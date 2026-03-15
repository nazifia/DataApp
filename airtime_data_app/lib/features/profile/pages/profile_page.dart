// User Profile Page
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/event/auth_event.dart';
import '../../authentication/state/auth_state.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/pin_input_dialog.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/constants/theme.dart';
import '../../../main.dart' show themeModeNotifier;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  String? _profilePictureUrl;
  bool _hasPinSet = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    // Populate from current auth state
    final state = context.read<AuthBloc>().state;
    if (state is AuthSuccess) {
      _fullNameController.text = state.fullName;
      _emailController.text = state.email ?? '';
      _profilePictureUrl = state.profilePicture;
    } else {
      context.read<AuthBloc>().add(LoadProfileEvent());
    }

    _checkPin();
  }

  Future<void> _checkPin() async {
    final has = await PinService.hasPin();
    if (mounted) setState(() => _hasPinSet = has);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() => _isEditing = !_isEditing);
    if (_isEditing) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: 'Save Changes',
        message:
            'Update your profile name to "${_fullNameController.text.trim()}"?',
        confirmLabel: 'Save',
        icon: Icons.save_rounded,
      );

      if (confirmed != true || !mounted) return;

      context.read<AuthBloc>().add(
            UpdateProfileEvent(_fullNameController.text.trim()),
          );
      setState(() => _isEditing = false);
      _animController.reverse();
    }
  }

  // ── Change Password ──────────────────────────────────────────────────────

  void _showChangePasswordSheet() {
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: BlocConsumer<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is PasswordChangedSuccess) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password changed successfully'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (state is PasswordChangedFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.lock_reset_rounded,
                                      color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Current Password
                            _fieldLabel('Current Password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: currentPwCtrl,
                              obscureText: obscureCurrent,
                              decoration: InputDecoration(
                                hintText: 'Enter current password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureCurrent
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setSheetState(() =>
                                      obscureCurrent = !obscureCurrent),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your current password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // New Password
                            _fieldLabel('New Password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: newPwCtrl,
                              obscureText: obscureNew,
                              decoration: InputDecoration(
                                hintText: 'Enter new password (min. 6 chars)',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureNew
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setSheetState(
                                      () => obscureNew = !obscureNew),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (v) {
                                if (v == null || v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            _fieldLabel('Confirm New Password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: confirmPwCtrl,
                              obscureText: obscureConfirm,
                              decoration: InputDecoration(
                                hintText: 'Repeat new password',
                                prefixIcon: const Icon(
                                    Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setSheetState(() =>
                                      obscureConfirm = !obscureConfirm),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (v) {
                                if (v != newPwCtrl.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (formKey.currentState
                                                ?.validate() ??
                                            false) {
                                          context
                                              .read<AuthBloc>()
                                              .add(ChangePasswordEvent(
                                            currentPwCtrl.text,
                                            newPwCtrl.text,
                                          ));
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white),
                                      )
                                    : const Text('Change Password',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Transaction PIN ──────────────────────────────────────────────────────

  Future<void> _handleTransactionPin() async {
    if (_hasPinSet) {
      // Changing PIN: verify current first, then set new
      final currentPin = await PinInputDialog.show(
        context,
        title: 'Enter Current PIN',
        subtitle: 'Verify your current transaction PIN',
      );
      if (currentPin == null || !mounted) return;
      final valid = await PinService.verifyPin(currentPin);
      if (!valid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (!mounted) return;
      await _setNewPin();
    } else {
      // Setting new PIN
      await _setNewPin();
    }
  }

  Future<void> _setNewPin() async {
    // Ask for new PIN
    final newPin = await PinInputDialog.show(
      context,
      title: _hasPinSet ? 'Enter New PIN' : 'Set Transaction PIN',
      subtitle: 'Choose a 4-digit PIN for authorising transactions',
    );
    if (newPin == null || !mounted) return;

    // Confirm new PIN
    final confirmPin = await PinInputDialog.show(
      context,
      title: 'Confirm New PIN',
      subtitle: 'Re-enter your new PIN to confirm',
    );
    if (confirmPin == null || !mounted) return;

    if (newPin != confirmPin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs do not match. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await PinService.setPin(newPin);
    if (!mounted) return;
    setState(() => _hasPinSet = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            _hasPinSet ? 'Transaction PIN updated' : 'Transaction PIN set'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Profile Picture ──────────────────────────────────────────────────────

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _pickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _pickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_profilePictureUrl != null)
                    _pickerOption(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove',
                      color: AppColors.error,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: implement remove profile picture
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        context.read<AuthBloc>().add(
              UpdateProfilePictureEvent(pickedFile.path),
            );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _toggleEditing,
            child: Text(
              _isEditing ? 'Cancel' : 'Edit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _fullNameController.text = state.fullName;
            _emailController.text = state.email ?? '';
            _profilePictureUrl = state.profilePicture;
            if (_isEditing) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else if (state is ProfileSuccess) {
            final data = state.profileData;
            _fullNameController.text =
                data['full_name']?.toString() ?? '';
            _emailController.text = data['email']?.toString() ?? '';
            _profilePictureUrl = data['profile_picture']?.toString();
          } else if (state is ProfileFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading =
              state is AuthLoading || state is ProfileLoading;
          final isUploadingPicture = state is ProfileLoading;

          String name = _fullNameController.text.isEmpty
              ? 'User'
              : _fullNameController.text;
          String phone = '';
          if (state is AuthSuccess) phone = state.phoneNumber;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Gradient Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary,
                        Color(0xFF1A3A6A),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Avatar with camera button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: _isEditing
                                ? _showImagePickerOptions
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 52,
                                    backgroundColor: Colors.white
                                        .withValues(alpha: 0.2),
                                    backgroundImage:
                                        _profilePictureUrl != null
                                            ? NetworkImage(
                                                _profilePictureUrl!)
                                            : null,
                                    child: _profilePictureUrl == null
                                        ? Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  // Upload progress overlay
                                  if (isUploadingPicture)
                                    Container(
                                      width: 104,
                                      height: 104,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black
                                            .withValues(alpha: 0.5),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Form Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // ── Personal Information Card ──────────────────────
                        _cardContainer(
                          title: 'Personal Information',
                          children: [
                            // Full Name
                            _fieldLabel('Full Name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fullNameController,
                              enabled: _isEditing,
                              textCapitalization:
                                  TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'Enter your full name',
                                prefixIcon: const Icon(
                                    Icons.person_outline_rounded),
                                fillColor: _isEditing
                                    ? Colors.white
                                    : Colors.grey[50],
                                filled: true,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email
                            _fieldLabel('Email Address'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              enabled: _isEditing,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Enter your email (optional)',
                                prefixIcon:
                                    const Icon(Icons.email_outlined),
                                fillColor: _isEditing
                                    ? Colors.white
                                    : Colors.grey[50],
                                filled: true,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return null;
                                }
                                if (!RegExp(
                                        r'^[\w\.\+\-]+@[\w\-]+\.\w{2,}$')
                                    .hasMatch(value.trim())) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone (read-only)
                            _fieldLabel('Phone Number'),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: phone,
                              enabled: false,
                              decoration: InputDecoration(
                                prefixIcon:
                                    const Icon(Icons.phone_outlined),
                                fillColor: Colors.grey[50],
                                filled: true,
                                disabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.divider),
                                ),
                                suffixIcon: const Tooltip(
                                  message:
                                      'Phone number cannot be changed',
                                  child: Icon(
                                      Icons.lock_outline_rounded,
                                      size: 18,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),

                        // Edit mode actions with animation
                        SizeTransition(
                          sizeFactor: _fadeAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        isLoading ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: AppColors.primary
                                          .withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Text('Saving...',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight
                                                              .w700)),
                                            ],
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.save_rounded,
                                                  size: 20),
                                              SizedBox(width: 10),
                                              Text('Save Changes',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight
                                                              .w700,
                                                      letterSpacing:
                                                          0.3)),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Account Security Card ──────────────────────────
                        _cardContainer(
                          title: 'Account Security',
                          children: [
                            // Change Password
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.lock_reset_rounded,
                                    color: AppColors.primary,
                                    size: 20),
                              ),
                              title: const Text(
                                'Change Password',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: const Text(
                                'Update your account password',
                                style: TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary),
                              onTap: _showChangePasswordSheet,
                            ),
                            const Divider(height: 1),

                            // Transaction PIN
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.warning
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.pin_outlined,
                                    color: AppColors.warning,
                                    size: 20),
                              ),
                              title: Text(
                                _hasPinSet
                                    ? 'Change Transaction PIN'
                                    : 'Set Transaction PIN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                _hasPinSet
                                    ? 'PIN is active — tap to change'
                                    : 'Add an extra layer of security',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasPinSet)
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary),
                                ],
                              ),
                              onTap: _handleTransactionPin,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Appearance Card ────────────────────────────────
                        _cardContainer(
                          title: 'Appearance',
                          children: [
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: themeModeNotifier,
                              builder: (context, mode, _) {
                                final isDark =
                                    mode == ThemeMode.dark;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.indigo
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isDark
                                          ? Icons.dark_mode_rounded
                                          : Icons.light_mode_rounded,
                                      color: Colors.indigo,
                                      size: 20,
                                    ),
                                  ),
                                  title: const Text(
                                    'Dark Mode',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isDark
                                        ? 'Dark theme is on'
                                        : 'Light theme is on',
                                    style: const TextStyle(
                                        fontSize: 12),
                                  ),
                                  trailing: Switch.adaptive(
                                    value: isDark,
                                    activeColor: AppColors.primary,
                                    onChanged: (value) async {
                                      final newMode = value
                                          ? ThemeMode.dark
                                          : ThemeMode.light;
                                      themeModeNotifier.value = newMode;
                                      await ThemeService.saveThemeMode(
                                          newMode);
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Account (Sign Out) Card ────────────────────────
                        _cardContainer(
                          title: 'Account',
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.error
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.logout_rounded,
                                    color: AppColors.error, size: 20),
                              ),
                              title: const Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: const Text(
                                'You will be signed out of this device',
                                style: TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary),
                              onTap: () async {
                                final confirmed =
                                    await ConfirmationDialog.show(
                                  context: context,
                                  title: 'Sign Out',
                                  message:
                                      'Are you sure you want to sign out of this device?',
                                  confirmLabel: 'Sign Out',
                                  icon: Icons.logout_rounded,
                                  isDangerous: true,
                                );

                                if (confirmed != true) return;
                                if (!context.mounted) return;

                                context
                                    .read<AuthBloc>()
                                    .add(const LogoutEvent());
                                if (!context.mounted) return;
                                Navigator.of(context)
                                    .pushNamedAndRemoveUntil(
                                        '/welcome', (route) => false);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cardContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
