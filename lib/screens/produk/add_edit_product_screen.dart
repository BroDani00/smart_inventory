import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/app_bar.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedSupplierId;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    if (widget.product != null) _populateForm();
  }

  Future<void> _loadSuppliers() async {
    final supplierProvider = Provider.of<SupplierProvider>(
      context,
      listen: false,
    );
    await supplierProvider.loadSuppliers();
  }

  void _populateForm() {
    final p = widget.product!;
    _codeController.text = p.code;
    _nameController.text = p.name;
    _categoryController.text = p.category;
    _stockController.text = p.stock.toString();
    _minStockController.text = p.minStock.toString();
    _costPriceController.text = p.costPrice.toString();
    _sellPriceController.text = p.sellPrice.toString();
    _descriptionController.text = p.description ?? '';
    _selectedSupplierId = p.supplierId;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  // Helper untuk menampilkan dialog error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveProduct() async {
    // Validasi form kosong
    if (!_formKey.currentState!.validate()) return;

    // 🔥 PARSING ANGKA DENGAN tryParse (AMAN, TIDAK CRASH)
    final stock = int.tryParse(_stockController.text.trim());
    final minStock = int.tryParse(_minStockController.text.trim());
    final costPrice = double.tryParse(_costPriceController.text.trim());
    final sellPrice = double.tryParse(_sellPriceController.text.trim());

    // Validasi hasil parsing
    if (stock == null) {
      _showError('Stok harus berupa angka');
      return;
    }
    if (minStock == null) {
      _showError('Batas minimum harus angka');
      return;
    }
    if (costPrice == null) {
      _showError('Harga modal harus angka');
      return;
    }
    if (sellPrice == null) {
      _showError('Harga jual harus angka');
      return;
    }

    // Validasi nilai tidak negatif
    if (stock < 0) {
      _showError('Stok tidak boleh negatif');
      return;
    }
    if (minStock < 0) {
      _showError('Batas minimum tidak boleh negatif');
      return;
    }
    if (costPrice < 0) {
      _showError('Harga modal tidak boleh negatif');
      return;
    }
    if (sellPrice < 0) {
      _showError('Harga jual tidak boleh negatif');
      return;
    }

    setState(() => _isLoading = true);

    final product = Product(
      id: widget.product?.id,
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      supplierId: _selectedSupplierId,
      stock: stock,
      minStock: minStock,
      costPrice: costPrice,
      sellPrice: sellPrice,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      imagePath: _imageFile?.path ?? widget.product?.imagePath,
    );

    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final bool success;

    if (widget.product == null) {
      success = await productProvider.addProduct(product);
    } else {
      success = await productProvider.updateProduct(product);
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? "Produk berhasil ditambahkan"
                : "Produk berhasil diupdate",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      final errorMsg =
          productProvider.errorMessage ??
          "Gagal menyimpan produk. Kode SKU mungkin sudah terdaftar.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.plusJakartaSans(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? AppColors.cardDark : Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.product != null;

    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(title: isEdit ? "Edit Produk" : "Tambah Produk Baru"),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker (sama seperti sebelumnya, tidak diubah)
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: AppColors.emeraldGradient,
                            borderRadius: BorderRadius.circular(24),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : (widget.product?.imagePath != null &&
                                          widget.product!.imagePath!.isNotEmpty
                                      ? DecorationImage(
                                          image: FileImage(
                                            File(widget.product!.imagePath!),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                          ),
                          child:
                              (_imageFile == null &&
                                  (widget.product?.imagePath?.isEmpty ?? true))
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Upload Gambar",
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: Colors.black.withAlpha(77),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildTextField(
                      controller: _codeController,
                      label: "Kode Barang / SKU",
                      hint: "Contoh: PRD001",
                      icon: Icons.barcode_reader,
                      validator: (val) => val?.isEmpty == true
                          ? "Kode barang harus diisi"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: "Nama Barang",
                      hint: "Contoh: Kopi Premium",
                      icon: Icons.inventory_2_rounded,
                      validator: (val) => val?.isEmpty == true
                          ? "Nama barang harus diisi"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _categoryController,
                      label: "Kategori",
                      hint: "Contoh: Makanan",
                      icon: Icons.category_rounded,
                      validator: (val) =>
                          val?.isEmpty == true ? "Kategori harus diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    // Supplier Dropdown (perbaiki deprecated value -> initialValue)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedSupplierId, // ✅ perbaikan
                        decoration: InputDecoration(
                          labelText: "Supplier",
                          prefixIcon: const Icon(Icons.business_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark ? AppColors.cardDark : Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("Pilih Supplier"),
                          ),
                          ...supplierProvider.suppliers.map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedSupplierId = val),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _stockController,
                            label: "Stok Awal",
                            hint: "0",
                            icon: Icons.warehouse_rounded,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Stok harus diisi';
                              if (int.tryParse(val) == null)
                                return 'Stok harus angka';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _minStockController,
                            label: "Batas Minimum",
                            hint: "5",
                            icon: Icons.warning_amber_rounded,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Batas minimum harus diisi';
                              if (int.tryParse(val) == null)
                                return 'Batas minimum harus angka';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _costPriceController,
                            label: "Harga Modal",
                            hint: "0",
                            icon: Icons.attach_money_rounded,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Harga modal harus diisi';
                              if (double.tryParse(val) == null)
                                return 'Harga modal harus angka';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _sellPriceController,
                            label: "Harga Jual",
                            hint: "0",
                            icon: Icons.price_change_rounded,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Harga jual harus diisi';
                              if (double.tryParse(val) == null)
                                return 'Harga jual harus angka';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _descriptionController,
                      label: "Deskripsi Produk",
                      hint: "Masukkan deskripsi...",
                      icon: Icons.description_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEdit ? "UPDATE PRODUK" : "SIMPAN PRODUK",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
