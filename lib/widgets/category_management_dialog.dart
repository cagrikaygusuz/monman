import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/category.dart';
import '../providers/app_state_provider.dart';

class CategoryManagementDialog extends StatefulWidget {
  final Category? category;
  final CategoryType categoryType;

  const CategoryManagementDialog({
    super.key,
    this.category,
    required this.categoryType,
  });

  @override
  State<CategoryManagementDialog> createState() => _CategoryManagementDialogState();
}

class _CategoryManagementDialogState extends State<CategoryManagementDialog> {
  final _nameController = TextEditingController();
  String _selectedColor = '#4CAF50';
  late CategoryType _categoryType;

  final List<String> _availableColors = [
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _categoryType = widget.categoryType;
    
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedColor = widget.category!.color;
      _categoryType = widget.category!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showColorPicker(BuildContext context, bool isTurkish) {
    Color currentColor = Color(int.parse(_selectedColor.substring(1), radix: 16) + 0xFF000000);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTurkish ? 'Renk Seç' : 'Pick Color'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              currentColor = color;
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isTurkish ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedColor = '#${currentColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              });
              Navigator.of(context).pop();
            },
            child: Text(isTurkish ? 'Seç' : 'Select'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final isTurkish = context.watch<AppStateProvider>().selectedLanguage == 'Turkish';
    
    return AlertDialog(
      title: Text(isEditing 
        ? (isTurkish ? 'Kategoriyi Düzenle' : 'Edit Category')
        : (isTurkish ? 'Yeni Kategori' : 'New Category')
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Kategori Adı' : 'Category Name',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTurkish ? 'Kategori Tipi' : 'Category Type',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<CategoryType>(
              segments: [
                ButtonSegment(
                  value: CategoryType.income,
                  label: Text(isTurkish ? 'Gelir' : 'Income'),
                  icon: const Icon(Icons.trending_up),
                ),
                ButtonSegment(
                  value: CategoryType.expense,
                  label: Text(isTurkish ? 'Gider' : 'Expense'),
                  icon: const Icon(Icons.trending_down),
                ),
                ButtonSegment(
                  value: CategoryType.billSubscription,
                  label: Text(isTurkish ? 'Fatura' : 'Bills'),
                  icon: const Icon(Icons.receipt_long),
                ),
              ],
              selected: {_categoryType},
              onSelectionChanged: (Set<CategoryType> selection) {
                setState(() {
                  _categoryType = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              isTurkish ? 'Renk Seçin' : 'Select Color',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            // Quick Colors Section
            Text(
              isTurkish ? 'Hızlı Renkler' : 'Quick Colors',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 90,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableColors.length,
                itemBuilder: (context, index) {
                  final color = _availableColors[index];
                  final isSelected = color == _selectedColor;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                        shape: BoxShape.circle,
                        border: isSelected
                          ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                          : Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Color Palette Section
            Text(
              isTurkish ? 'Özel Renk Seç' : 'Custom Color',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(_selectedColor.substring(1), radix: 16) + 0xFF000000),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showColorPicker(context, isTurkish),
                    icon: const Icon(Icons.palette),
                    label: Text(isTurkish ? 'Renk Paleti' : 'Color Palette'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isTurkish ? 'İptal' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _nameController.text.trim().isEmpty ? null : () => _saveCategory(),
          child: Text(isEditing 
            ? (isTurkish ? 'Güncelle' : 'Update')
            : (isTurkish ? 'Kaydet' : 'Save')
          ),
        ),
      ],
    );
  }

  void _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      final now = DateTime.now();
      
      if (widget.category != null) {
        // Edit existing category
        final updatedCategory = widget.category!.copyWith(
          name: name,
          type: _categoryType,
          color: _selectedColor,
          updatedAt: now,
        );
        
        await context.read<AppStateProvider>().updateCategory(updatedCategory);
      } else {
        // Add new category
        final newCategory = Category(
          name: name,
          type: _categoryType,
          color: _selectedColor,
          createdAt: now,
          updatedAt: now,
        );
        
        await context.read<AppStateProvider>().addCategory(newCategory);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AppStateProvider>().selectedLanguage == 'Turkish'
              ? 'Kategori kaydedilirken bir hata oluştu'
              : 'Error saving category'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}