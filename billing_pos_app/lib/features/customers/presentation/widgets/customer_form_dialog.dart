import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "../../models/customer_model.dart";
import "../customer_state.dart";

class CustomerFormDialog extends ConsumerStatefulWidget {
  final CustomerModel? customer;
  final String? initialMobile;

  const CustomerFormDialog({super.key, this.customer, this.initialMobile});

  @override
  ConsumerState<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _gstinController;
  late bool _emailConsent;
  late bool _whatsappConsent;
  late bool _isActive;
  bool _sameAsMobile = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.customerName ?? "");
    _mobileController = TextEditingController(text: c?.mobileNumber ?? widget.initialMobile ?? "");
    _whatsappController = TextEditingController(text: c?.whatsAppNumber ?? widget.initialMobile ?? "");
    _emailController = TextEditingController(text: c?.email ?? "");
    _addressController = TextEditingController(text: c?.address ?? "");
    _gstinController = TextEditingController(text: c?.gstin ?? "");
    _emailConsent = c?.emailConsent ?? true;
    _whatsappConsent = c?.whatsAppConsent ?? true;
    _isActive = c?.isActive ?? true;
    _sameAsMobile = c == null || c.whatsAppNumber == c.mobileNumber;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    final isMobile = MediaQuery.sizeOf(context).width < 550;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? "Edit Customer Profile" : "Add New Customer",
                        style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Customer Name *",
                      hintText: "e.g. Karthik Raja",
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? "Customer name is required." : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            labelText: "Mobile Number (10 Digits) *",
                            hintText: "9876543210",
                            prefixText: "+91 ",
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                            counterText: "",
                          ),
                          onChanged: (v) {
                            if (_sameAsMobile) {
                              _whatsappController.text = v;
                            }
                          },
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Mobile number is required.";
                            final regex = RegExp(r"^[6-9]\d{9}$");
                            if (!regex.hasMatch(v.trim())) return "Enter valid 10-digit Indian mobile.";
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _sameAsMobile,
                        onChanged: (v) {
                          setState(() {
                            _sameAsMobile = v ?? true;
                            if (_sameAsMobile) {
                              _whatsappController.text = _mobileController.text;
                            }
                          });
                        },
                      ),
                      const Expanded(
                        child: Text("WhatsApp number same as mobile", style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  if (!_sameAsMobile) ...[
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: "WhatsApp Number",
                        hintText: "9876543210",
                        prefixText: "+91 ",
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                        border: OutlineInputBorder(),
                        counterText: "",
                      ),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final regex = RegExp(r"^[6-9]\d{9}$");
                          if (!regex.hasMatch(v.trim())) return "Invalid WhatsApp number.";
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (isMobile) ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email Address (Optional)",
                        hintText: "customer@example.com",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          if (!v.contains("@") || !v.contains(".")) return "Invalid email address.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _gstinController,
                      decoration: const InputDecoration(
                        labelText: "Customer GSTIN (B2B Billing)",
                        hintText: "33AAAAA0000A1Z5",
                        prefixIcon: Icon(Icons.receipt_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final regex = RegExp(r"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$");
                          if (!regex.hasMatch(v.trim().toUpperCase())) return "Invalid 15-char GSTIN.";
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Email Address (Optional)",
                              hintText: "customer@example.com",
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                if (!v.contains("@") || !v.contains(".")) return "Invalid email address.";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _gstinController,
                            decoration: const InputDecoration(
                              labelText: "Customer GSTIN (B2B Billing)",
                              hintText: "33AAAAA0000A1Z5",
                              prefixIcon: Icon(Icons.receipt_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                final regex = RegExp(r"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$");
                                if (!regex.hasMatch(v.trim().toUpperCase())) return "Invalid 15-char GSTIN.";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Address / Locality",
                      hintText: "e.g. Anna Nagar, Chennai",
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text("Digital Invoicing Consent", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("WhatsApp Invoicing Consent", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("Receive digital receipts on WhatsApp", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _whatsappConsent,
                    onChanged: (v) => setState(() => _whatsappConsent = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Email Invoicing Consent", style: TextStyle(fontSize: 14)),
                    subtitle: const Text("Receive PDF tax invoice copies via Email", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: _emailConsent,
                    onChanged: (v) => setState(() => _emailConsent = v),
                  ),
                  if (isEditing)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Active Account", style: TextStyle(fontSize: 14)),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (_formKey.currentState?.validate() ?? false) {
                                  setState(() => _isSubmitting = true);
                                  final name = _nameController.text.trim();
                                  final mobile = _mobileController.text.trim();
                                  final wa = _whatsappController.text.trim();
                                  final email = _emailController.text.trim();
                                  final address = _addressController.text.trim();
                                  final gstin = _gstinController.text.trim().toUpperCase();

                                  bool ok;
                                  if (isEditing) {
                                    final req = UpdateCustomerRequest(
                                      customerName: name,
                                      mobileNumber: mobile,
                                      whatsAppNumber: wa.isNotEmpty ? wa : null,
                                      email: email.isNotEmpty ? email : null,
                                      address: address.isNotEmpty ? address : null,
                                      gstin: gstin.isNotEmpty ? gstin : null,
                                      emailConsent: _emailConsent,
                                      whatsAppConsent: _whatsappConsent,
                                      isActive: _isActive,
                                    );
                                    ok = await ref.read(customerNotifierProvider.notifier).updateCustomer(widget.customer!.id, req);
                                  } else {
                                    final req = CreateCustomerRequest(
                                      customerName: name,
                                      mobileNumber: mobile,
                                      whatsAppNumber: wa.isNotEmpty ? wa : null,
                                      email: email.isNotEmpty ? email : null,
                                      address: address.isNotEmpty ? address : null,
                                      gstin: gstin.isNotEmpty ? gstin : null,
                                      emailConsent: _emailConsent,
                                      whatsAppConsent: _whatsappConsent,
                                    );
                                    ok = await ref.read(customerNotifierProvider.notifier).createCustomer(req);
                                  }

                                  if (mounted) {
                                    setState(() => _isSubmitting = false);
                                  }
                                  if (ok && context.mounted) {
                                    Navigator.of(context).pop(true);
                                  }
                                }
                              },
                        child: _isSubmitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(isEditing ? "Save Changes" : "Save Customer"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

