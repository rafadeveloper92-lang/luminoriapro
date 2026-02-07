import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/license_config.dart';
import '../../../core/services/license_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/support_ticket_service.dart';
import '../../../core/services/admin_stats_service.dart';

/// Filtros da lista de assinaturas.
enum SubscriptionFilter {
  all('Todos'),
  expiresIn3Days('Vencem em 3 dias'),
  expired('Já venceram');

  const SubscriptionFilter(this.label);
  final String label;
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  List<SubscriptionRecord> _all = [];
  List<SubscriptionRecord> _filtered = [];
  SubscriptionFilter _filter = SubscriptionFilter.all;
  bool _loading = true;
  String? _error;
  List<SupportTicketRecord> _tickets = [];
  bool _ticketsLoading = false;
  List<PaymentEventRecord> _paymentEvents = [];
  bool _paymentEventsLoading = false;
  int _totalUserCount = 0;
  int _onlineCount = 0;
  List<NewSubscribersByDay> _newSubscribersByDay = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_ticketsLoading && _tickets.isEmpty) _loadTickets();
      if (_tabController.index == 2 && !_paymentEventsLoading && _paymentEvents.isEmpty) _loadPaymentEvents();
    });
    _load();
    _loadAdminStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await LicenseService.instance.fetchAllSubscriptions();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
        _applyFilter();
      });
    } catch (e) {
      ServiceLocator.log.e('Admin fetch subscriptions failed', tag: 'AdminPanel', error: e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _filtered = [];
      });
    }
  }

  Future<void> _loadAdminStats() async {
    try {
      final total = await AdminStatsService.instance.getTotalUserCount();
      final online = await AdminStatsService.instance.getOnlineCount();
      final chart = await AdminStatsService.instance.getNewSubscribersByDay(days: 7);
      if (!mounted) return;
      setState(() {
        _totalUserCount = total;
        _onlineCount = online;
        _newSubscribersByDay = chart;
      });
    } catch (e) {
      if (!mounted) return;
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _ticketsLoading = true);
    try {
      final list = await SupportTicketService.instance.fetchAllTickets();
      if (!mounted) return;
      setState(() {
        _tickets = list;
        _ticketsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _ticketsLoading = false);
    }
  }

  Future<void> _loadPaymentEvents() async {
    setState(() => _paymentEventsLoading = true);
    try {
      final list = await AdminStatsService.instance.fetchPaymentEvents();
      if (!mounted) return;
      setState(() {
        _paymentEvents = list;
        _paymentEventsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _paymentEventsLoading = false);
    }
  }

  void _applyFilter() {
    switch (_filter) {
      case SubscriptionFilter.all:
        _filtered = List.from(_all);
        break;
      case SubscriptionFilter.expiresIn3Days:
        _filtered = _all.where((s) => s.expiresInThreeDays).toList();
        break;
      case SubscriptionFilter.expired:
        _filtered = _all.where((s) => s.isExpired).toList();
        break;
    }
  }

  void _openEditDialog(SubscriptionRecord record) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _EditSubscriptionDialog(
        record: record,
        onSaved: () {
          Navigator.of(ctx).pop();
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.getBackgroundColor(context);
    final surface = AppTheme.getSurfaceColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimaryColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text('Painel Administrativo', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            tooltip: 'Gerar teste 2h',
            onPressed: () => _showCreateTestDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) {
            if (i == 1) _loadTickets();
            if (i == 2) _loadPaymentEvents();
          },
          tabs: [
            Tab(text: 'Assinaturas', icon: const Icon(Icons.people)),
            Tab(text: 'Chamados', icon: const Icon(Icons.support_agent)),
            Tab(text: 'Pagamentos', icon: const Icon(Icons.payment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildSubscriptionsTab(context, bg, surface, textPrimary, textSecondary, primary),
          _buildTicketsTab(context, bg, surface, textPrimary, textSecondary, primary),
          _buildPaymentsTab(context, bg, surface, textPrimary, textSecondary, primary),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsTab(
    BuildContext context,
    Color bg,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color primary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          // Resumo (dashboard)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              color: AppTheme.getCardColor(context),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _buildStatChip(context, 'Contas', '$_totalUserCount', Icons.person),
                        const SizedBox(width: 8),
                        _buildStatChip(context, 'Online', '$_onlineCount', Icons.circle, isOnline: true),
                        const SizedBox(width: 8),
                        _buildStatChip(context, 'Total', '${_all.length}', Icons.people_outline),
                        const SizedBox(width: 8),
                        _buildStatChip(context, 'Ativos', '${_all.where((s) => s.isActive).length}', Icons.check_circle_outline),
                        const SizedBox(width: 8),
                        _buildStatChip(context, 'Novos (7d)', '${_all.where((s) => s.createdAt != null && DateTime.now().toUtc().difference(s.createdAt!).inDays <= 7).length}', Icons.fiber_new),
                        const SizedBox(width: 8),
                        _buildStatChip(context, 'MRR ~', '${(_all.where((s) => s.isActive).length * 2.99).toStringAsFixed(0)}€', Icons.euro),
                      ],
                    ),
                    if (_newSubscribersByDay.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Novos assinantes (últimos 7 dias)', style: TextStyle(color: textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 120,
                        child: _buildNewSubscribersChart(context, primary, textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Stripe (config do .env)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              color: AppTheme.getCardColor(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: primary, size: 22),
                        const SizedBox(width: 8),
                        Text('Stripe', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildConfigRow('ID do Produto', EnvConfig.stripeProductId.isEmpty ? '—' : EnvConfig.stripeProductId),
                    const SizedBox(height: 6),
                    _buildConfigRow('Preço (Price ID)', EnvConfig.stripePriceId.isEmpty ? '—' : EnvConfig.stripePriceId),
                    if (!EnvConfig.isStripeConfigured)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Configure STRIPE_PUBLISHABLE_KEY e STRIPE_PRICE_ID no .env',
                          style: TextStyle(color: AppTheme.warningColor, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SubscriptionFilter.values.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _filter = f;
                          _applyFilter();
                        });
                      },
                      selectedColor: primary.withOpacity(0.3),
                      checkmarkColor: primary,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Lista de assinaturas
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                              const SizedBox(height: 16),
                              Text(_error!, style: TextStyle(color: textSecondary), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              _filter == SubscriptionFilter.all ? 'Nenhuma assinatura.' : 'Nenhum resultado para este filtro.',
                              style: TextStyle(color: textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await _load();
                              await _loadAdminStats();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final s = _filtered[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: AppTheme.getCardColor(context),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: s.isActive ? AppTheme.successColor.withOpacity(0.2) : AppTheme.errorColor.withOpacity(0.2),
                                      child: Icon(
                                        s.isActive ? Icons.check : Icons.block,
                                        color: s.isActive ? AppTheme.successColor : AppTheme.errorColor,
                                      ),
                                    ),
                                    title: Text(
                                      s.userId != null ? 'User: ${s.userId!.substring(0, 8)}...' : (s.deviceId.isNotEmpty ? s.deviceId : '—'),
                                      style: TextStyle(color: textPrimary, fontSize: 13, fontFamily: 'monospace'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'Expira: ${_formatDate(s.expiresAt)} • ${s.plan ?? "—"}${s.notes?.isNotEmpty == true ? "\n${s.notes}" : ""}',
                                      style: TextStyle(color: textSecondary, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (v) async {
                                        if (v == 'edit') _openEditDialog(s);
                                        if (v == 'ban') await _banSubscription(s);
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Editar')])),
                                        const PopupMenuItem(value: 'ban', child: Row(children: [Icon(Icons.block, color: Colors.red), SizedBox(width: 8), Text('Banir')])),
                                      ],
                                    ),
                                    onTap: () => _openEditDialog(s),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      );
  }

  Widget _buildStatChip(BuildContext context, String label, String value, IconData icon, {bool isOnline = false}) {
    final textSecondary = AppTheme.getTextSecondary(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOnline)
            Icon(Icons.circle, size: 12, color: _onlineCount > 0 ? AppTheme.successColor : textSecondary)
          else
            Icon(icon, size: 18, color: textSecondary),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: TextStyle(fontSize: 10, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildNewSubscribersChart(BuildContext context, Color primary, Color textSecondary) {
    final maxY = _newSubscribersByDay.isEmpty ? 1.0 : (_newSubscribersByDay.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble() + 1);
    final spots = _newSubscribersByDay.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < _newSubscribersByDay.length) {
                  final d = _newSubscribersByDay[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${d.day}/${d.month}', style: TextStyle(color: textSecondary, fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: textSecondary, fontSize: 10)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: spots.map((s) => BarChartGroupData(
          x: s.x.toInt(),
          barRods: [
            BarChartRodData(
              toY: s.y,
              color: primary,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
          showingTooltipIndicators: [],
        )).toList(),
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  Future<void> _banSubscription(SubscriptionRecord s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Banir utilizador'),
        content: const Text('Cortar o acesso imediatamente? A data de expiração será definida no passado.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Banir'), style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await LicenseService.instance.updateSubscription(
        s.id,
        expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        plan: s.plan,
        notes: (s.notes ?? '') + (s.notes?.isNotEmpty == true ? ' ' : '') + '[Banido]',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acesso revogado.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.errorColor));
    }
  }

  void _showCreateTestDialog(BuildContext context) {
    final userIdController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerar código de teste (2h)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cole o user_id do utilizador (UUID). O acesso ficará ativo por 2 horas.'),
            const SizedBox(height: 16),
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID (UUID)',
                border: OutlineInputBorder(),
                hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final uid = userIdController.text.trim();
              if (uid.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indique o user_id.')));
                return;
              }
              try {
                await LicenseService.instance.createOrUpdateLicense(
                  userId: uid,
                  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 2)),
                  plan: 'teste_2h',
                  notes: 'Teste 2 horas',
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acesso de teste (2h) ativado.')));
                _load();
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.errorColor));
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsTab(BuildContext context, Color bg, Color surface, Color textPrimary, Color textSecondary, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Chamados de suporte', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _ticketsLoading ? null : _loadTickets),
            ],
          ),
        ),
        Expanded(
          child: _ticketsLoading
              ? const Center(child: CircularProgressIndicator())
              : _tickets.isEmpty
                  ? Center(child: Text('Nenhum chamado.', style: TextStyle(color: textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final t = _tickets[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppTheme.getCardColor(context),
                          child: ExpansionTile(
                            title: Text(t.subject, style: TextStyle(color: textPrimary, fontSize: 14)),
                            subtitle: Text('${t.email} • ${_formatDate(t.createdAt)} • ${t.status}', style: TextStyle(color: textSecondary, fontSize: 11)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.message, style: TextStyle(color: textPrimary, fontSize: 13)),
                                    if (t.adminReply != null) ...[
                                      const SizedBox(height: 12),
                                      Text('Resposta: ${t.adminReply}', style: TextStyle(color: textSecondary, fontSize: 12)),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (t.status != 'closed')
                                          TextButton(
                                            onPressed: () async {
                                              await SupportTicketService.instance.updateTicket(t.id, status: 'closed');
                                              _loadTickets();
                                            },
                                            child: const Text('Fechar'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab(BuildContext context, Color bg, Color surface, Color textPrimary, Color textSecondary, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Histórico de pagamentos (Stripe)', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _paymentEventsLoading ? null : _loadPaymentEvents),
            ],
          ),
        ),
        Expanded(
          child: _paymentEventsLoading
              ? const Center(child: CircularProgressIndicator())
              : _paymentEvents.isEmpty
                  ? Center(child: Text('Nenhum evento de pagamento.', style: TextStyle(color: textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _paymentEvents.length,
                      itemBuilder: (context, index) {
                        final e = _paymentEvents[index];
                        final isFailed = e.type == 'invoice.payment_failed';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppTheme.getCardColor(context),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isFailed ? AppTheme.errorColor.withOpacity(0.2) : AppTheme.successColor.withOpacity(0.2),
                              child: Icon(
                                isFailed ? Icons.warning_amber : Icons.check_circle,
                                color: isFailed ? AppTheme.errorColor : AppTheme.successColor,
                              ),
                            ),
                            title: Text(
                              e.type,
                              style: TextStyle(color: textPrimary, fontSize: 13, fontFamily: 'monospace'),
                            ),
                            subtitle: Text(
                              '${e.customerEmail ?? "—"} • ${e.amountCents != null ? "${(e.amountCents! / 100).toStringAsFixed(2)} ${e.currency?.toUpperCase() ?? ""}" : "—"}${e.failureReason != null ? "\n${e.failureReason}" : ""}',
                              style: TextStyle(color: textSecondary, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              _formatDate(e.createdAt),
                              style: TextStyle(color: textSecondary, fontSize: 11),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildConfigRow(String label, String value) {
    final textSecondary = AppTheme.getTextSecondary(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(color: textSecondary, fontSize: 12))),
        Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _EditSubscriptionDialog extends StatefulWidget {
  final SubscriptionRecord record;
  final VoidCallback onSaved;

  const _EditSubscriptionDialog({required this.record, required this.onSaved});

  @override
  State<_EditSubscriptionDialog> createState() => _EditSubscriptionDialogState();
}

class _EditSubscriptionDialogState extends State<_EditSubscriptionDialog> {
  late bool _active;
  late DateTime _expiresAt;
  late TextEditingController _notesController;
  String? _plan;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _active = widget.record.isActive;
    _expiresAt = widget.record.expiresAt.toLocal();
    _notesController = TextEditingController(text: widget.record.notes ?? '');
    _plan = widget.record.plan;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _expiresAt = DateTime(picked.year, picked.month, picked.day, _expiresAt.hour, _expiresAt.minute);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      var expires = _expiresAt;
      if (!_active) {
        expires = DateTime.now().toUtc().subtract(const Duration(days: 1));
      }
      await LicenseService.instance.updateSubscription(
        widget.record.id,
        expiresAt: expires,
        plan: _plan,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assinatura atualizada.')));
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.getSurfaceColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    return AlertDialog(
      backgroundColor: surface,
      title: const Text('Editar assinatura'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.record.userId ?? widget.record.deviceId, style: TextStyle(color: textSecondary, fontSize: 12, fontFamily: 'monospace')),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Acesso ativo', style: TextStyle(color: textPrimary)),
              subtitle: Text(_active ? 'Cliente pode usar o app' : 'Acesso bloqueado', style: TextStyle(color: textSecondary, fontSize: 12)),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text('Data de expiração', style: TextStyle(color: textPrimary)),
              subtitle: Text(
                '${_expiresAt.day.toString().padLeft(2, '0')}/${_expiresAt.month.toString().padLeft(2, '0')}/${_expiresAt.year}',
                style: TextStyle(color: textSecondary),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _active ? _pickDate : null,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                hintText: 'Ex: Cliente João - Plano Anual',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
        ),
      ],
    );
  }
}
