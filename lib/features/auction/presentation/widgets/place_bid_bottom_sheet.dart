import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:live_auction/core/constants/app_colors.dart';
import 'package:live_auction/features/auction/data/models/product_model.dart';
import 'package:live_auction/features/auction/presentation/providers/auction_providers.dart';
import 'package:live_auction/features/auth/presentation/providers/auth_provider.dart';
import 'package:live_auction/shared/widgets/custom_button.dart';

class PlaceBidBottomSheet extends ConsumerStatefulWidget {
  final ProductModel product;

  const PlaceBidBottomSheet({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<PlaceBidBottomSheet> createState() => _PlaceBidBottomSheetState();
}

class _PlaceBidBottomSheetState extends ConsumerState<PlaceBidBottomSheet> {
  late double _minRequiredBid;
  late double _selectedBidAmount;
  final TextEditingController _customBidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _minRequiredBid = p.totalBids == 0
        ? p.startingPrice
        : p.currentHighestBid + p.minimumBidIncrement;
    _selectedBidAmount = _minRequiredBid;
    _customBidController.text = _selectedBidAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _customBidController.dispose();
    super.dispose();
  }

  void _addIncrement(double amount) {
    setState(() {
      _selectedBidAmount += amount;
      _customBidController.text = _selectedBidAmount.toStringAsFixed(0);
    });
  }

  Future<void> _submitBid() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place a bid')),
      );
      return;
    }

    final parsed = double.tryParse(_customBidController.text);
    if (parsed == null || parsed < _minRequiredBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum bid required is ₹${_minRequiredBid.toStringAsFixed(0)}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(biddingControllerProvider.notifier).placeBid(
          productId: widget.product.id,
          userId: user.uid,
          userName: user.name,
          profileImage: user.profileImage,
          bidAmount: parsed,
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.black),
                const SizedBox(width: 10),
                Text('Bid of ₹${parsed.toStringAsFixed(0)} placed successfully!'),
              ],
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final biddingState = ref.watch(biddingControllerProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Place Your Bid',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Highest Bid Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Highest Bid', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(widget.product.currentHighestBid > 0
                          ? widget.product.currentHighestBid
                          : widget.product.startingPrice),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Min Required', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(_minRequiredBid),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Increment Buttons
          const Text(
            'Quick Add',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [100.0, 500.0, 1000.0, 2000.0].map((inc) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _addIncrement(inc),
                    child: Text(
                      '+₹${inc.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Custom Input
          const Text(
            'Bid Amount (₹)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customBidController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
              hintText: _minRequiredBid.toStringAsFixed(0),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
            ),
            onChanged: (val) {
              final p = double.tryParse(val);
              if (p != null) {
                _selectedBidAmount = p;
              }
            },
          ),
          const SizedBox(height: 24),

          // Error message if any
          if (biddingState.errorMessage != null) ...[
            Text(
              biddingState.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],

          // Submit Button
          CustomButton(
            text: 'Confirm & Place Bid',
            isLoading: biddingState.isLoading,
            onPressed: _submitBid,
          ),
        ],
      ),
    );
  }
}
