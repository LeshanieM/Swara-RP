import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swara/core/constants/app_constants.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/features/auth/data/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _childNameController = TextEditingController();
  final _childAgeController = TextEditingController();
  String _email = '';
  String _role = '';
  bool _isChildAccount = false;
  bool _loaded = false;

  Future<void> _pickProfilePhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null || !mounted) return;

    final success = await ref.read(authProvider.notifier).updateProfilePhoto(image);
    if (!mounted) return;
    final error = ref.read(authProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'පැතිකඩ ඡායාරූපය යාවත්කාලීන කළා' : (error ?? 'ඡායාරූපය එක් කළ නොහැක. නැවත උත්සාහ කරන්න.')),
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _childNameController.dispose();
    _childAgeController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    if (_loaded) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    _loaded = true;
    _nameController.text = user.name;
    _email = user.email;
    _role = user.role;
    _isChildAccount = user.role == AppConstants.roleChild || user.child != null;
    _childNameController.text = user.child?.firstName ?? '';
    _childAgeController.text = user.child?.age.toString() ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).updateProfile(
          name: _nameController.text,
          childFirstName: _isChildAccount ? _childNameController.text : null,
          childAge: _isChildAccount ? int.tryParse(_childAgeController.text) : null,
        );
    if (!mounted) return;
    final error = ref.read(authProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'පැතිකඩ යාවත්කාලීන කළා'
          : (error ?? 'යාවත්කාලීන කළ නොහැක. නැවත උත්සාහ කරන්න.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    _loadProfile();
    final busy = ref.watch(authProvider).isLoading;
    final profileUser = ref.watch(authProvider).user;
    final photoUrl = profileUser?.photoUrl;
    ImageProvider? profileImage;
    if (photoUrl != null) {
      if (photoUrl.startsWith('data:image/')) {
        profileImage = MemoryImage(
          base64Decode(photoUrl.substring(photoUrl.indexOf(',') + 1)),
        );
      } else if (photoUrl.startsWith('http') ||
          photoUrl.startsWith('/api/profile/photo/')) {
        profileImage = NetworkImage(
          Uri.parse(AppConstants.baseUrl).resolve(photoUrl).toString(),
          headers: photoUrl.startsWith('/api/profile/photo/') &&
                  profileUser?.token != null
              ? {'Authorization': 'Bearer ${profileUser!.token}'}
              : null,
        );
      }
    }
    return Scaffold(
      backgroundColor: AppColors.groundAdult,
      appBar: AppBar(
        title: const Text('Profile · පැතිකඩ'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Sign out · ඉවත් වන්න',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: CalmSceneBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    SwaraCard(
                      color: Colors.white.withValues(alpha: 0.94),
                      child: Row(
                        children: [
                          Semantics(
                            button: _isChildAccount,
                            label: 'පැතිකඩ ඡායාරූපය වෙනස් කරන්න',
                            child: InkWell(
                              onTap: _isChildAccount && !busy ? _pickProfilePhoto : null,
                              customBorder: const CircleBorder(),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: AppColors.primaryWash,
                                    backgroundImage: profileImage,
                                    child: photoUrl == null
                                        ? Icon(
                                            _isChildAccount ? Icons.child_care_rounded : Icons.person_rounded,
                                            size: 36,
                                            color: AppColors.primaryDeep,
                                          )
                                        : null,
                                  ),
                                  if (_isChildAccount)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppColors.primaryDeep,
                                        child: Icon(
                                          busy ? Icons.hourglass_top_rounded : Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('මගේ ගිණුම', style: AppTextStyles.titleMedium),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _role == 'therapist'
                                      ? 'චිකිත්සක ගිණුම'
                                      : _role == 'child'
                                          ? 'දරුවාගේ ගිණුම'
                                          : 'දෙමාපිය ගිණුම',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwaraCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ගිණුම් විස්තර', style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'නම',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'නම ඇතුළත් කරන්න'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            initialValue: _email,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'විද්‍යුත් තැපෑල',
                              prefixIcon: Icon(Icons.email_outlined),
                              helperText: 'වෙනස් කළ නොහැක',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'ගිණුම් වර්ගය',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            child: Text(_role == 'therapist'
                                ? 'චිකිත්සක'
                                : _role == 'child'
                                    ? 'දරුවා'
                                    : _role),
                          ),
                        ],
                      ),
                    ),
                    if (_isChildAccount) ...[
                    const SizedBox(height: AppSpacing.md),
                    SwaraCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('දරුවාගේ විස්තර', style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _childNameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'මුල් නම',
                              prefixIcon: Icon(Icons.child_friendly_outlined),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'දරුවාගේ නම ඇතුළත් කරන්න'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _childAgeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'වයස (5–14)',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                            validator: (value) {
                              final age = int.tryParse(value ?? '');
                              if (age == null || age < 5 || age > 14) {
                                return 'වයස 5 සිට 14 දක්වා ඇතුළත් කරන්න';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: SwaraButton(
                        label: 'වෙනස්කම් සුරකින්න',
                        icon: Icons.save_outlined,
                        isLoading: busy,
                        onPressed: _save,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: SwaraButton(
                        label: 'ප්‍රගතිය බලන්න',
                        icon: Icons.trending_up_rounded,
                        outlined: true,
                        onPressed: () => context.push('/progress'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: SwaraButton(
                        label: 'වාණිජකරණය',
                        icon: Icons.insights_rounded,
                        outlined: true,
                        onPressed: () => context.go('/commercialization'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
