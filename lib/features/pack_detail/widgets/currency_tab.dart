import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/config/theme/app_colors.dart';
import '/core/utils/extensions.dart';
import '/core/utils/format_utils.dart';
import '/core/widgets/section_card.dart';
import '/core/widgets/stat_tile.dart';
import '/core/widgets/status_pill.dart';
import '/features/pack_detail/pack_detail_state.dart';

/// The converter tab: a conversion that works in airplane mode, the provenance
/// of the saved rate snapshot, and the practical money advice for the country.
class PackCurrencyTab extends StatelessWidget {
  final PackDetailState state;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String> onFromChanged;
  final ValueChanged<String> onToChanged;
  final VoidCallback onSwap;

  const PackCurrencyTab({
    super.key,
    required this.state,
    required this.onAmountChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final facts = state.data?.facts;
    final rates = state.data?.rates;
    final tips = state.data?.tips;
    final codes = rates?.currencies ?? const <String>[];
    final fetchedAt = rates?.fetchedAt;
    final convertedAmount = state.convertedAmount;
    final unitRate = state.unitRate;
    final isStale = rates?.isStale() ?? false;
    final cashVsCard = facts?.cashVsCard ?? '';
    final dailyBudget = facts?.dailyBudget ?? '';
    final currencyTips = tips?.currency ?? const <String>[];

    return ListView(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 28.h),
      children: <Widget>[
        SectionCard(
          title: 'Converter',
          icon: Icons.currency_exchange_rounded,
          children: <Widget>[
            StatTile(
              icon: Icons.flag_outlined,
              label: 'Pack currency',
              value: facts?.currency.label ?? 'Unknown',
            ),
            StatTile(
              icon: Icons.attach_money_rounded,
              label: 'Symbol',
              value: facts?.currency.symbol ?? '-',
            ),
            SizedBox(height: 8.h),
            TextFormField(
              key: ValueKey<String>(state.fromCurrency + state.toCurrency),
              initialValue: state.amountText,
              onChanged: onAmountChanged,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            SizedBox(height: 10.h),
            Row(
              children: <Widget>[
                Expanded(
                  child: _CurrencyDropdown(
                    label: 'From',
                    value: state.fromCurrency,
                    codes: codes,
                    onChanged: onFromChanged,
                  ),
                ),
                IconButton(
                  onPressed: onSwap,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  tooltip: 'Swap currencies',
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: _CurrencyDropdown(
                    label: 'To',
                    value: state.toCurrency,
                    codes: codes,
                    onChanged: onToChanged,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _ConversionResult(
              convertedAmount: convertedAmount,
              toCurrency: state.toCurrency,
              toSymbol: state.toSymbol,
              hasRates: rates?.hasRates == true,
            ),
            if (unitRate != null) ...<Widget>[
              SizedBox(height: 6.h),
              Text(
                '1 ${state.fromCurrency} = '
                '${formatMoney(unitRate, state.toSymbol)}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        SectionCard(
          title: 'Rate snapshot',
          icon: Icons.info_outline_rounded,
          children: <Widget>[
            StatTile(
              icon: Icons.source_outlined,
              label: 'Source',
              value: rates?.source ?? 'Unknown',
            ),
            StatTile(
              icon: Icons.schedule_rounded,
              label: 'Fetched',
              value: fetchedAt == null ? 'Unknown' : formatRelative(fetchedAt),
            ),
            StatTile(
              icon: Icons.flag_outlined,
              label: 'Base',
              value: rates?.base ?? 'Unknown',
            ),
            StatTile(
              icon: Icons.list_alt_rounded,
              label: 'Currencies',
              value: '${rates?.rates.length ?? 0}',
            ),
            if (isStale) ...<Widget>[
              SizedBox(height: 8.h),
              const StatusPill(
                label: 'STALE',
                color: AppColors.warning,
                icon: Icons.history_rounded,
              ),
              SizedBox(height: 6.h),
              Text(
                'These rates are a saved snapshot from the last time this pack '
                'was online, so they may have drifted since.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
        if (cashVsCard.isNotEmpty || dailyBudget.isNotEmpty)
          SectionCard(
            title: 'Money on the ground',
            icon: Icons.payments_outlined,
            children: <Widget>[
              if (cashVsCard.isNotEmpty)
                _LabelledParagraph(label: 'Cash vs card', text: cashVsCard),
              if (dailyBudget.isNotEmpty)
                _LabelledParagraph(label: 'Daily budget', text: dailyBudget),
              if (currencyTips.isNotEmpty) ...<Widget>[
                SizedBox(height: 4.h),
                ...currencyTips.map<Widget>(
                  (String text) => BulletLine(text: text),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// The converted amount, or an explicit reason why there is not one.
class _ConversionResult extends StatelessWidget {
  final double? convertedAmount;
  final String toCurrency;
  final String toSymbol;
  final bool hasRates;

  const _ConversionResult({
    required this.convertedAmount,
    required this.toCurrency,
    required this.toSymbol,
    required this.hasRates,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final amount = convertedAmount;

    if (amount == null) {
      return Text(
        hasRates
            ? 'Rate unavailable for this pair'
            : 'No exchange rate saved yet - connect once and refresh',
        style: context.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Flexible(
          child: Text(
            formatMoney(amount, toSymbol),
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Padding(
          padding: EdgeInsets.only(bottom: 3.h),
          child: Text(
            toCurrency,
            style: context.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// One currency picker. The saved code may not exist in the snapshot yet, so
/// the initial value is dropped rather than tripping the dropdown's assert.
class _CurrencyDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> codes;
  final ValueChanged<String> onChanged;

  const _CurrencyDropdown({
    required this.label,
    required this.value,
    required this.codes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty && codes.contains(value);

    return DropdownButtonFormField<String>(
      initialValue: hasValue ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: codes
          .map<DropdownMenuItem<String>>(
            (String code) =>
                DropdownMenuItem<String>(value: code, child: Text(code)),
          )
          .toList(),
      onChanged: (String? selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

class _LabelledParagraph extends StatelessWidget {
  final String label;
  final String text;

  const _LabelledParagraph({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 3.h),
          Text(text, style: context.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}
