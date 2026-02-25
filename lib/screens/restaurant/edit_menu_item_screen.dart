// lib/screens/restaurant/edit_menu_item_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/menu_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/menu_item_model.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../theme/neumorphic_theme.dart';
import '../../services/ai_image_service.dart';

class EditMenuItemScreen extends StatefulWidget {
  final MenuItem menuItem;

  const EditMenuItemScreen({Key? key, required this.menuItem})
      : super(key: key);

  @override
  State<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends State<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  late String _selectedCategory;
  File? _newImageFile;
  bool _isSubmitting = false;
  bool _isAiAnalyzing = false;
  bool _isAiGenerating = false;
  String? _aiSuggestions;

  final List<String> _categories = [
    'Entree',
    'Plat principal',
    'Dessert',
    'Boisson',
    'Accompagnement',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menuItem.name);
    _descriptionController =
        TextEditingController(text: widget.menuItem.description);
    _priceController =
        TextEditingController(text: widget.menuItem.price.toString());
    _selectedCategory = widget.menuItem.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFile = await showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changePhoto),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto),
              onTap: () async {
                Navigator.pop(
                  context,
                  await picker.pickImage(source: ImageSource.camera),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () async {
                Navigator.pop(
                  context,
                  await picker.pickImage(source: ImageSource.gallery),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
        _aiSuggestions = null;
      });
    }
  }

  Future<void> _analyzeWithAi() async {
    if (_newImageFile == null) return;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    setState(() {
      _isAiAnalyzing = true;
      _aiSuggestions = null;
    });

    final result = await AiImageService().analyzeDishPhoto(
      _newImageFile!,
      _nameController.text.trim(),
      language: locale,
    );

    if (mounted) {
      setState(() {
        _isAiAnalyzing = false;
        _aiSuggestions = result ?? l10n.aiAnalysisError;
      });
    }
  }

  Future<void> _generateWithAi() async {
    final l10n = AppLocalizations.of(context)!;
    final dishName = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (dishName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiNeedDishName), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isAiGenerating = true);

    final result = await AiImageService().generateDishImage(
      dishName,
      description.isNotEmpty ? description : dishName,
    );

    if (mounted) {
      setState(() {
        _isAiGenerating = false;
        if (result != null) {
          _newImageFile = result;
          _aiSuggestions = null;
        }
      });
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiGenerationError), backgroundColor: NeuColors.error),
        );
      }
    }
  }

  Future<void> _generateFromPrompt() async {
    final l10n = AppLocalizations.of(context)!;
    final promptController = TextEditingController();

    final prompt = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiCustomPrompt),
        content: TextField(
          controller: promptController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.aiPromptHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, promptController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: NeuColors.accent),
            child: Text(l10n.generate),
          ),
        ],
      ),
    );

    if (prompt == null || prompt.isEmpty) return;

    setState(() => _isAiGenerating = true);

    final result = await AiImageService().generateFromPrompt(prompt);

    if (mounted) {
      setState(() {
        _isAiGenerating = false;
        if (result != null) {
          _newImageFile = result;
          _aiSuggestions = null;
        }
      });
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiGenerationError), backgroundColor: NeuColors.error),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final restaurantId = authProvider.currentUser?.uid;

    if (restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userNotConnected)),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await context.read<MenuProvider>().updateMenuItem(
          itemId: widget.menuItem.id,
          restaurantId: restaurantId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory,
          newImageFile: _newImageFile,
        );

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _newImageFile != null
                ? l10n.dishModifiedPending
                : l10n.dishModifiedSuccess,
          ),
          backgroundColor:
              _newImageFile != null ? Colors.orange : NeuColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.modificationError),
          backgroundColor: NeuColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        title: Text(l10n.editDish),
        backgroundColor: NeuColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: NeuDecoration.pressed(radius: 12),
                  child: _newImageFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _newImageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.newPhoto,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : widget.menuItem.imageUrl != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.menuItem.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.edit,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.changePhoto,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo,
                                    size: 50, color: NeuColors.textHint),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.addPhoto,
                                  style: const TextStyle(
                                      color: NeuColors.textSecondary),
                                ),
                              ],
                            ),
                ),
              ),
              if (_newImageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Text(
                      l10n.newPhotoPending,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // AI Image buttons row
              Row(
                children: [
                  if (_newImageFile != null)
                    Expanded(
                      child: _isAiAnalyzing
                          ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)))))
                          : OutlinedButton.icon(
                              onPressed: _analyzeWithAi,
                              icon: const Icon(Icons.auto_fix_high, size: 18, color: Color(0xFF7C3AED)),
                              label: Text(l10n.aiAnalyzePhoto, style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF7C3AED)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                    ),
                  if (_newImageFile != null) const SizedBox(width: 8),
                  Expanded(
                    child: _isAiGenerating
                        ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)))))
                        : OutlinedButton.icon(
                            onPressed: _generateWithAi,
                            icon: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF7C3AED)),
                            label: Text(l10n.aiGeneratePhoto, style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF7C3AED)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  if (!_isAiGenerating)
                    IconButton(
                      onPressed: _generateFromPrompt,
                      icon: const Icon(Icons.edit_note, color: Color(0xFF7C3AED)),
                      tooltip: l10n.aiCustomPrompt,
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),

              // AI Suggestions
              if (_aiSuggestions != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8B4FE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_fix_high, size: 18, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 8),
                          Text(l10n.aiSuggestions, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _aiSuggestions = null),
                            child: const Icon(Icons.close, size: 18, color: Color(0xFF7C3AED)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_aiSuggestions!, style: const TextStyle(fontSize: 13, color: NeuColors.textPrimary)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Name
              Container(
                decoration: NeuDecoration.pressed(radius: 14),
                child: TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: NeuColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.dishName,
                    labelStyle:
                        const TextStyle(color: NeuColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: NeuColors.accent, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: NeuColors.error, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: NeuColors.error, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    prefixIcon:
                        const Icon(Icons.restaurant, color: NeuColors.accent),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.enterNameValidation;
                    }
                    if (value.trim().length < 3) {
                      return l10n.nameTooShort;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Container(
                decoration: NeuDecoration.pressed(radius: 14),
                child: TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: NeuColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.descriptionRequired,
                    labelStyle:
                        const TextStyle(color: NeuColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: NeuColors.accent, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: NeuColors.error, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: NeuColors.error, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    prefixIcon: const Icon(Icons.description,
                        color: NeuColors.accent),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.enterDescriptionValidation;
                    }
                    if (value.trim().length < 10) {
                      return l10n.descriptionTooShort;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Category
              Container(
                decoration: NeuDecoration.pressed(radius: 14),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: const TextStyle(color: NeuColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    labelStyle:
                        const TextStyle(color: NeuColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: NeuColors.accent, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    prefixIcon:
                        const Icon(Icons.category, color: NeuColors.accent),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Price
              Container(
                decoration: NeuDecoration.pressed(radius: 14),
                child: TextFormField(
                  controller: _priceController,
                  style: const TextStyle(color: NeuColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.priceRequired,
                    labelStyle:
                        const TextStyle(color: NeuColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: NeuColors.accent, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: NeuColors.error, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: NeuColors.error, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    prefixText: l10n.dhs,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.enterPriceValidation;
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null) {
                      return l10n.invalidPrice;
                    }
                    if (price <= 0) {
                      return l10n.pricePositive;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeuColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.saveChanges,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
