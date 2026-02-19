import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/license_config.dart';
import '../../../core/services/license_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/support_ticket_service.dart';
import '../../../core/services/admin_stats_service.dart';
import '../../../core/services/shop_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/models/shop_product.dart';
import '../../../core/models/shop_banner.dart';
import '../../../core/models/profile_theme.dart';
import '../../profile/border_definitions.dart';
import '../../profile/theme_presets.dart';

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
  List<ShopOrderRecord> _shopOrders = [];
  List<ShopProduct> _shopProducts = [];
  List<ShopBanner> _shopBanners = [];
  List<ProfileTheme> _themes = [];
  bool _shopOrdersLoading = false;
  bool _shopProductsLoading = false;
  bool _shopBannersLoading = false;
  bool _themesLoading = false;
  bool _shopOrdersFilterPending = true;
  List<AdminUserProfile> _accounts = [];
  bool _accountsLoading = false;
  final TextEditingController _accountsSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_ticketsLoading && _tickets.isEmpty) _loadTickets();
      if (_tabController.index == 2 && !_paymentEventsLoading && _paymentEvents.isEmpty) _loadPaymentEvents();
      if (_tabController.index == 3 && !_shopOrdersLoading && _shopOrders.isEmpty) _loadShopOrders();
      if (_tabController.index == 3 && !_shopProductsLoading && _shopProducts.isEmpty) _loadShopProducts();
      if (_tabController.index == 3 && !_shopBannersLoading && _shopBanners.isEmpty) _loadShopBanners();
      if (_tabController.index == 4 && !_themesLoading && _themes.isEmpty) _loadThemes();
      if (_tabController.index == 5 && !_accountsLoading && _accounts.isEmpty) _loadAccounts();
    });
    _load();
    _loadAdminStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _accountsSearchController.dispose();
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

  Future<void> _loadShopOrders() async {
    setState(() => _shopOrdersLoading = true);
    try {
      final list = await ShopService.instance.getAllOrdersForAdmin();
      if (!mounted) return;
      setState(() {
        _shopOrders = list;
        _shopOrdersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _shopOrdersLoading = false);
    }
  }

  Future<void> _loadShopProducts() async {
    setState(() => _shopProductsLoading = true);
    try {
      final list = await ShopService.instance.getAllProductsForAdmin();
      if (!mounted) return;
      setState(() {
        _shopProducts = list;
        _shopProductsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _shopProductsLoading = false);
    }
  }

  Future<void> _loadShopBanners() async {
    setState(() => _shopBannersLoading = true);
    try {
      final list = await ShopService.instance.getAllBannersForAdmin();
      if (!mounted) return;
      setState(() {
        _shopBanners = list;
        _shopBannersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _shopBannersLoading = false);
    }
  }

  Future<void> _loadThemes() async {
    setState(() => _themesLoading = true);
    try {
      final list = await ThemeService.instance.getAllThemesForAdmin();
      if (!mounted) return;
      setState(() {
        _themes = list;
        _themesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _themesLoading = false);
    }
  }

  Future<void> _loadAccounts() async {
    setState(() => _accountsLoading = true);
    try {
      final list = await AdminStatsService.instance.fetchAllUserProfiles();
      if (!mounted) return;
      setState(() {
        _accounts = list;
        _accountsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _accountsLoading = false);
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
            if (i == 3) {
              _loadShopOrders();
              _loadShopProducts();
              _loadShopBanners();
            }
            if (i == 4) _loadThemes();
            if (i == 5) _loadAccounts();
          },
          tabs: [
            Tab(text: 'Assinaturas', icon: const Icon(Icons.people)),
            Tab(text: 'Chamados', icon: const Icon(Icons.support_agent)),
            Tab(text: 'Pagamentos', icon: const Icon(Icons.payment)),
            Tab(text: 'Loja', icon: const Icon(Icons.shopping_bag)),
            Tab(text: 'Temas', icon: const Icon(Icons.palette)),
            Tab(text: 'Contas', icon: const Icon(Icons.person_search)),
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
          _buildShopTab(context, bg, surface, textPrimary, textSecondary, primary),
          _buildThemesTab(context, bg, surface, textPrimary, textSecondary, primary),
          _buildAccountsTab(context, bg, surface, textPrimary, textSecondary, primary),
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

  String _accountInitial(AdminUserProfile a) {
    final s = a.displayName ?? a.userId;
    if (s.isEmpty) return '?';
    return s.substring(0, 1).toUpperCase();
  }

  List<AdminUserProfile> get _accountsFiltered {
    final q = _accountsSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return _accounts;
    return _accounts.where((a) {
      final name = (a.displayName ?? '').toLowerCase();
      final id = a.userId.toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  void _showAccountOptions(BuildContext context, AdminUserProfile profile, Color textPrimary, Color textSecondary, Color primary) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.getCardColor(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                profile.displayName?.isNotEmpty == true ? profile.displayName! : 'Sem nome',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(profile.userId, style: TextStyle(color: textSecondary, fontSize: 12, fontFamily: 'monospace')),
              Text('Moedas: ${profile.coins}', style: TextStyle(color: textSecondary, fontSize: 14)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copiar ID'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: profile.userId));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID copiado para a área de transferência.')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Adicionar moedas'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAddCoinsDialog(context, profile, primary);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCoinsDialog(BuildContext context, AdminUserProfile profile, Color primary) {
    final amountController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar moedas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Utilizador: ${profile.displayName?.isNotEmpty == true ? profile.displayName! : profile.userId}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade de moedas',
                border: OutlineInputBorder(),
                hintText: 'Ex: 100',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text.trim());
              if (amount == null || amount < 1) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indique uma quantidade válida (número positivo).')));
                return;
              }
              try {
                await AdminStatsService.instance.addCoinsToUser(profile.userId, amount);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$amount moedas adicionadas à conta.')));
                _loadAccounts();
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.errorColor));
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsTab(BuildContext context, Color bg, Color surface, Color textPrimary, Color textSecondary, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _accountsSearchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por nome ou ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: surface,
                  ),
                  style: TextStyle(color: textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _accountsLoading ? null : _loadAccounts,
                tooltip: 'Atualizar lista',
              ),
            ],
          ),
        ),
        Expanded(
          child: _accountsLoading
              ? const Center(child: CircularProgressIndicator())
              : _accountsFiltered.isEmpty
                  ? Center(
                      child: Text(
                        _accounts.isEmpty ? 'Nenhuma conta encontrada.' : 'Nenhum resultado para a pesquisa.',
                        style: TextStyle(color: textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _accountsFiltered.length,
                      itemBuilder: (context, index) {
                        final a = _accountsFiltered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppTheme.getCardColor(context),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primary.withOpacity(0.2),
                              backgroundImage: a.avatarUrl != null && a.avatarUrl!.isNotEmpty ? NetworkImage(a.avatarUrl!) : null,
                              child: a.avatarUrl == null || a.avatarUrl!.isEmpty ? Text(_accountInitial(a), style: TextStyle(color: primary)) : null,
                            ),
                            title: Text(a.displayName?.isNotEmpty == true ? a.displayName! : 'Sem nome', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500)),
                            subtitle: Text('ID: ${a.userId} • ${a.coins} moedas', style: TextStyle(color: textSecondary, fontSize: 11, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showAccountOptions(context, a, textPrimary, textSecondary, primary),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildShopTab(BuildContext context, Color bg, Color surface, Color textPrimary, Color textSecondary, Color primary) {
    final ordersFiltered = _shopOrdersFilterPending
        ? _shopOrders.where((o) => o.status == 'pending').toList()
        : _shopOrders;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pedidos da loja', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('Pendentes'),
                selected: _shopOrdersFilterPending,
                onSelected: (v) => setState(() => _shopOrdersFilterPending = true),
                selectedColor: primary.withOpacity(0.3),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Todos'),
                selected: !_shopOrdersFilterPending,
                onSelected: (v) => setState(() => _shopOrdersFilterPending = false),
                selectedColor: primary.withOpacity(0.3),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _shopOrdersLoading ? null : _loadShopOrders),
            ],
          ),
          const SizedBox(height: 8),
          _shopOrdersLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              : ordersFiltered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _shopOrdersFilterPending ? 'Nenhum pedido pendente.' : 'Nenhum pedido.',
                        style: TextStyle(color: textSecondary),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ordersFiltered.length,
                      itemBuilder: (context, index) {
                        final o = ordersFiltered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppTheme.getCardColor(context),
                          child: ListTile(
                            title: Text(
                              o.productName ?? o.productId,
                              style: TextStyle(color: textPrimary, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${o.deliveryName ?? "—"} • ${o.deliveryAddress ?? "—"} • ${o.deliveryPhone ?? "—"} • CEP ${o.deliveryPostalCode ?? "—"} • ${_formatDate(o.createdAt)} • ${o.status}',
                              style: TextStyle(color: textSecondary, fontSize: 11),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: o.status == 'pending'
                                ? FilledButton.tonal(
                                    onPressed: () async {
                                      await ShopService.instance.updateOrderStatus(o.id, 'shipped');
                                      _loadShopOrders();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido marcado como enviado.')));
                                    },
                                    child: const Text('Enviado'),
                                  )
                                : Text(o.status, style: TextStyle(color: textSecondary, fontSize: 12)),
                          ),
                        );
                      },
                    ),
          const SizedBox(height: 24),
          Text('Produtos', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Novo produto'),
                onPressed: () => _openProductDialog(context, null),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _shopProductsLoading ? null : _loadShopProducts),
            ],
          ),
          const SizedBox(height: 8),
          _shopProductsLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              : _shopProducts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Nenhum produto. Clique em Novo produto.', style: TextStyle(color: textSecondary)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _shopProducts.length,
                      itemBuilder: (context, index) {
                        final p = _shopProducts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppTheme.getCardColor(context),
                          child: ListTile(
                            title: Text(p.name, style: TextStyle(color: textPrimary, fontSize: 14)),
                            subtitle: Text(
                              '${p.priceCoins} Luminárias • ${p.active ? "Ativo" : "Inativo"}',
                              style: TextStyle(color: textSecondary, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _openProductDialog(context, p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remover produto?'),
                                        content: Text('Remover "${p.name}"? Isto não pode ser desfeito.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor), child: const Text('Remover')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ShopService.instance.deleteProductForAdmin(p.id);
                                      _loadShopProducts();
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () => _openProductDialog(context, p),
                          ),
                        );
                      },
                    ),
          const SizedBox(height: 24),
          Text('Banners de Propaganda', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Novo banner'),
                onPressed: () => _openBannerDialog(context, null),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _shopBannersLoading ? null : _loadShopBanners),
            ],
          ),
          const SizedBox(height: 8),
          _shopBannersLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              : _shopBanners.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Nenhum banner. Clique em Novo banner.', style: TextStyle(color: textSecondary)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _shopBanners.length,
                      itemBuilder: (context, index) {
                        final b = _shopBanners[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppTheme.getCardColor(context),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                b.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                            title: Text(
                              b.title,
                              style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (b.description != null && b.description!.isNotEmpty)
                                  Text(b.description!, style: TextStyle(color: textSecondary, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      b.active ? Icons.check_circle : Icons.cancel,
                                      size: 16,
                                      color: b.active ? Colors.green : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      b.active ? 'Ativo' : 'Inativo',
                                      style: TextStyle(
                                        color: b.active ? Colors.green : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Ordem: ${b.displayOrder}',
                                      style: TextStyle(color: textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  _openBannerDialog(context, b);
                                } else if (v == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Apagar banner'),
                                      content: Text('Tem certeza que deseja apagar "${b.title}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
                                          child: const Text('Apagar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ShopService.instance.deleteBannerForAdmin(b.id);
                                    _loadShopBanners();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner apagado.')));
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Editar')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Apagar')])),
                              ],
                            ),
                            onTap: () => _openBannerDialog(context, b),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildThemesTab(BuildContext context, Color bg, Color surface, Color textPrimary, Color textSecondary, Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Temas de Perfil', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _themesLoading ? null : _loadThemes),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Novo Tema'),
            onPressed: () => _openThemeDialog(context, null),
          ),
          const SizedBox(height: 16),
          _themesLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              : _themes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Nenhum tema. Clique em Novo Tema.', style: TextStyle(color: textSecondary)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _themes.length,
                      itemBuilder: (context, index) {
                        final t = _themes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppTheme.getCardColor(context),
                          child: ListTile(
                            leading: t.previewImageUrl != null && t.previewImageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      t.previewImageUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.palette),
                                    ),
                                  )
                                : const Icon(Icons.palette),
                            title: Text(t.name, style: TextStyle(color: textPrimary, fontSize: 14)),
                            subtitle: Text(
                              '${t.themeKey} • ${t.active ? "Ativo" : "Inativo"}',
                              style: TextStyle(color: textSecondary, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.preview),
                                  tooltip: 'Preview',
                                  onPressed: () => _showThemePreview(context, t),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _openThemeDialog(context, t),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remover tema?'),
                                        content: Text('Tem certeza que deseja remover "${t.name}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
                                            child: const Text('Remover'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ThemeService.instance.deleteThemeForAdmin(t.id);
                                      _loadThemes();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  void _showThemePreview(BuildContext context, ProfileTheme theme) {
    showDialog(
      context: context,
      builder: (ctx) => _ThemePreviewDialog(theme: theme),
    );
  }

  void _openProductDialog(BuildContext context, ShopProduct? product) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ShopProductEditDialog(
        product: product,
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadShopProducts();
        },
      ),
    );
  }

  void _openBannerDialog(BuildContext context, ShopBanner? banner) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ShopBannerEditDialog(
        banner: banner,
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadShopBanners();
        },
      ),
    );
  }

  void _openThemeDialog(BuildContext context, ProfileTheme? theme) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ThemeEditDialog(
        theme: theme,
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadThemes();
        },
      ),
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

class _ShopProductEditDialog extends StatefulWidget {
  final ShopProduct? product;
  final VoidCallback onSaved;

  const _ShopProductEditDialog({this.product, required this.onSaved});

  @override
  State<_ShopProductEditDialog> createState() => _ShopProductEditDialogState();
}

class _ShopProductEditDialogState extends State<_ShopProductEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlsController;
  late bool _active;
  late String _productType;
  String? _itemKey;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p != null ? '${p.priceCoins}' : '');
    _imageUrlsController = TextEditingController(
      text: p?.imageUrls.join('\n') ?? '',
    );
    _active = p?.active ?? true;
    _productType = p?.productType ?? 'physical';
    _itemKey = p?.itemKey;
    if (_productType == 'border' && _itemKey == null) {
      _itemKey = kBorderDefinitions.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final pf = result.files.single;
    File? file;
    var pathStr = pf.path;
    if (pathStr != null && pathStr.isNotEmpty) {
      if (pathStr.startsWith('file://')) pathStr = pathStr.substring(7);
      final f = File(pathStr);
      if (await f.exists()) file = f;
    }
    if (file == null && pf.bytes != null && pf.bytes!.isNotEmpty) {
      final dir = await getTemporaryDirectory();
      final ext = pf.extension ?? 'jpg';
      final tmp = File('${dir.path}/shop_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await tmp.writeAsBytes(pf.bytes!);
      if (await tmp.exists()) file = tmp;
    }
    if (file == null || !await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível acessar a imagem.'), backgroundColor: AppTheme.errorColor),
        );
      }
      return;
    }
    setState(() => _uploadingImage = true);
    try {
      final url = await ShopService.instance.uploadProductImage(file);
      if (!mounted) return;
      if (url != null) {
        final current = _imageUrlsController.text.trim();
        _imageUrlsController.text = current.isEmpty ? url : '$current\n$url';
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagem enviada. URL adicionada à lista.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha no upload. Verifique o bucket shop-products no Supabase.'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome obrigatório.'), backgroundColor: AppTheme.errorColor));
      return;
    }
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preço inválido (número >= 0).'), backgroundColor: AppTheme.errorColor));
      return;
    }
    final urls = _imageUrlsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    setState(() => _saving = true);
    try {
      final product = widget.product?.copyWith(
            name: name,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            priceCoins: price,
            imageUrls: urls,
            active: _active,
            productType: _productType,
            itemKey: (_productType == 'border' || _productType == 'theme') ? _itemKey : null,
          ) ??
          ShopProduct(
            id: '',
            name: name,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            priceCoins: price,
            imageUrls: urls,
            active: _active,
            productType: _productType,
            itemKey: (_productType == 'border' || _productType == 'theme') ? _itemKey : null,
          );
      final saved = await ShopService.instance.upsertProductForAdmin(product);
      if (!mounted) return;
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto salvo.')));
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar.'), backgroundColor: AppTheme.errorColor));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.errorColor));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.getSurfaceColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);

    return AlertDialog(
      backgroundColor: surface,
      title: Text(widget.product == null ? 'Novo produto' : 'Editar produto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Preço (Luminárias)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _productType,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'physical', child: Text('Físico')),
                DropdownMenuItem(value: 'border', child: Text('Borda')),
                DropdownMenuItem(value: 'theme', child: Text('Tema')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _productType = v;
                    if (v == 'border' && _itemKey == null) {
                      _itemKey = kBorderDefinitions.first.id;
                    }
                    if (v == 'theme') {
                      _itemKey = null; // Reset para permitir seleção manual
                    }
                  });
                }
              },
            ),
            if (_productType == 'border') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _itemKey,
                decoration: const InputDecoration(
                  labelText: 'Borda',
                  border: OutlineInputBorder(),
                ),
                items: kBorderDefinitions.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                onChanged: (v) => setState(() => _itemKey = v),
              ),
            ],
            if (_productType == 'theme') ...[
              const SizedBox(height: 12),
              FutureBuilder<List<ProfileTheme>>(
                future: ThemeService.instance.getAllThemesForAdmin(),
                builder: (context, snapshot) {
                  final themes = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _itemKey,
                    decoration: const InputDecoration(
                      labelText: 'Tema',
                      border: OutlineInputBorder(),
                      hintText: 'Selecione um tema',
                    ),
                    items: themes.map((t) => DropdownMenuItem(value: t.themeKey, child: Text(t.name))).toList(),
                    onChanged: (v) => setState(() => _itemKey = v),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlsController,
                    decoration: const InputDecoration(
                      labelText: 'URLs das Imagens (uma por linha)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _uploadingImage
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  onPressed: _uploadingImage ? null : _pickAndUploadImage,
                  tooltip: 'Enviar imagem',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text('Ativo', style: TextStyle(color: textPrimary)),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
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

class _ShopBannerEditDialog extends StatefulWidget {
  final ShopBanner? banner;
  final VoidCallback onSaved;

  const _ShopBannerEditDialog({this.banner, required this.onSaved});

  @override
  State<_ShopBannerEditDialog> createState() => _ShopBannerEditDialogState();
}

class _ShopBannerEditDialogState extends State<_ShopBannerEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _linkUrlController;
  late TextEditingController _displayOrderController;
  late bool _active;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleController = TextEditingController(text: b?.title ?? '');
    _descriptionController = TextEditingController(text: b?.description ?? '');
    _imageUrlController = TextEditingController(text: b?.imageUrl ?? '');
    _linkUrlController = TextEditingController(text: b?.linkUrl ?? '');
    _displayOrderController = TextEditingController(text: b != null ? '${b.displayOrder}' : '0');
    _active = b?.active ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _linkUrlController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final pf = result.files.single;
    File? file;
    var pathStr = pf.path;
    if (pathStr != null && pathStr.isNotEmpty) {
      if (pathStr.startsWith('file://')) pathStr = pathStr.substring(7);
      final f = File(pathStr);
      if (await f.exists()) file = f;
    }
    if (file == null && pf.bytes != null && pf.bytes!.isNotEmpty) {
      final dir = await getTemporaryDirectory();
      final ext = pf.extension ?? 'jpg';
      final tmp = File('${dir.path}/banner_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await tmp.writeAsBytes(pf.bytes!);
      if (await tmp.exists()) file = tmp;
    }
    if (file == null || !await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível acessar a imagem.'), backgroundColor: AppTheme.errorColor),
        );
      }
      return;
    }
    setState(() => _uploadingImage = true);
    try {
      final url = await ShopService.instance.uploadProductImage(file);
      if (!mounted) return;
      if (url != null) {
        _imageUrlController.text = url;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagem enviada.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha no upload. Verifique o bucket shop-products no Supabase.'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Título obrigatório.'), backgroundColor: AppTheme.errorColor));
      return;
    }
    final imageUrl = _imageUrlController.text.trim();
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL da imagem obrigatória.'), backgroundColor: AppTheme.errorColor));
      return;
    }
    final displayOrder = int.tryParse(_displayOrderController.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      final banner = widget.banner?.copyWith(
            title: title,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            imageUrl: imageUrl,
            linkUrl: _linkUrlController.text.trim().isEmpty ? null : _linkUrlController.text.trim(),
            active: _active,
            displayOrder: displayOrder,
          ) ??
          ShopBanner(
            id: '',
            title: title,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            imageUrl: imageUrl,
            linkUrl: _linkUrlController.text.trim().isEmpty ? null : _linkUrlController.text.trim(),
            active: _active,
            displayOrder: displayOrder,
          );
      final saved = await ShopService.instance.upsertBannerForAdmin(banner);
      if (!mounted) return;
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner salvo.')));
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar.'), backgroundColor: AppTheme.errorColor));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.errorColor));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.getSurfaceColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);

    return AlertDialog(
      backgroundColor: surface,
      title: Text(widget.banner == null ? 'Novo banner' : 'Editar banner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL da Imagem',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _uploadingImage
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  onPressed: _uploadingImage ? null : _pickAndUploadImage,
                  tooltip: 'Enviar imagem',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkUrlController,
              decoration: const InputDecoration(
                labelText: 'Link URL (opcional)',
                border: OutlineInputBorder(),
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _displayOrderController,
              decoration: const InputDecoration(
                labelText: 'Ordem de Exibição',
                border: OutlineInputBorder(),
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text('Ativo', style: TextStyle(color: textPrimary)),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
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

class _ThemePreviewDialog extends StatelessWidget {
  final ProfileTheme theme;

  const _ThemePreviewDialog({required this.theme});

  @override
  Widget build(BuildContext context) {
    final primaryColor = theme.primaryColorInt != null ? Color(theme.primaryColorInt!) : Colors.red;
    final secondaryColor = theme.secondaryColorInt != null ? Color(theme.secondaryColorInt!) : Colors.black;
    
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Preview: ${theme.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Stack(
                  children: [
                    if (theme.coverImageUrl != null && theme.coverImageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          theme.coverImageUrl!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            color: primaryColor,
                            child: Center(child: Icon(Icons.image, color: Colors.white54, size: 48)),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                      ),
                    Positioned(
                      top: 120,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: primaryColor,
                              child: const Icon(Icons.person, size: 40, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              theme.name,
                              style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _PreviewButton(
                                  label: 'Botão Primário',
                                  color: primaryColor,
                                  style: theme.buttonStyle,
                                ),
                                _PreviewButton(
                                  label: 'Botão Secundário',
                                  color: secondaryColor,
                                  style: theme.buttonStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (theme.decorativeElements != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Efeitos: ${theme.decorativeElements!['particles'] ?? 'Nenhum'}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  final String label;
  final Color color;
  final Map<String, dynamic>? style;

  const _PreviewButton({required this.label, required this.color, this.style});

  @override
  Widget build(BuildContext context) {
    final glow = style?['glow'] == true;
    final borderRadius = (style?['border_radius'] as num?)?.toDouble() ?? 12.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ThemeEditDialog extends StatefulWidget {
  final ProfileTheme? theme;
  final VoidCallback onSaved;

  const _ThemeEditDialog({this.theme, required this.onSaved});

  @override
  State<_ThemeEditDialog> createState() => _ThemeEditDialogState();
}

class _ThemeEditDialogState extends State<_ThemeEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _themeKeyController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverImageUrlController;
  late TextEditingController _backgroundMusicUrlController;
  late TextEditingController _primaryColorController;
  late TextEditingController _secondaryColorController;
  late TextEditingController _previewImageUrlController;
  late bool _active;
  Map<String, dynamic>? _buttonStyle;
  Map<String, dynamic>? _decorativeElements;
  String? _selectedPreset;
  bool _saving = false;
  bool _uploadingCover = false;
  bool _uploadingPreview = false;
  bool _uploadingMusic = false;

  @override
  void initState() {
    super.initState();
    final t = widget.theme;
    _nameController = TextEditingController(text: t?.name ?? '');
    _themeKeyController = TextEditingController(text: t?.themeKey ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _coverImageUrlController = TextEditingController(text: t?.coverImageUrl ?? '');
    _backgroundMusicUrlController = TextEditingController(text: t?.backgroundMusicUrl ?? '');
    _primaryColorController = TextEditingController(text: t?.primaryColor ?? '#E50914');
    _secondaryColorController = TextEditingController(text: t?.secondaryColor ?? '#000000');
    _previewImageUrlController = TextEditingController(text: t?.previewImageUrl ?? '');
    _active = t?.active ?? true;
    _buttonStyle = t?.buttonStyle;
    _decorativeElements = t?.decorativeElements;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _themeKeyController.dispose();
    _descriptionController.dispose();
    _coverImageUrlController.dispose();
    _backgroundMusicUrlController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _previewImageUrlController.dispose();
    super.dispose();
  }

  void _applyPreset(String presetName) {
    final preset = kThemePresets.firstWhere((p) => p.name == presetName);
    setState(() {
      _nameController.text = preset.name;
      _themeKeyController.text = preset.themeKey;
      _descriptionController.text = preset.description;
      _coverImageUrlController.text = preset.coverImageUrl ?? '';
      _backgroundMusicUrlController.text = preset.backgroundMusicUrl ?? '';
      _primaryColorController.text = preset.primaryColor;
      _secondaryColorController.text = preset.secondaryColor;
      _previewImageUrlController.text = preset.previewImageUrl ?? '';
      _buttonStyle = Map<String, dynamic>.from(preset.buttonStyle);
      _decorativeElements = Map<String, dynamic>.from(preset.decorativeElements);
      _selectedPreset = presetName;
    });
  }

  Future<void> _uploadCoverImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      File? imageFile;

      // Tentar usar path primeiro
      if (file.path != null && file.path!.isNotEmpty) {
        var pathStr = file.path!;
        if (pathStr.startsWith('file://')) pathStr = pathStr.substring(7);
        final f = File(pathStr);
        if (await f.exists()) imageFile = f;
      }

      // Fallback: usar bytes
      if (imageFile == null && file.bytes != null && file.bytes!.isNotEmpty) {
        final dir = await getTemporaryDirectory();
        final ext = file.extension ?? 'jpg';
        final tmp = File('${dir.path}/cover_${DateTime.now().millisecondsSinceEpoch}.$ext');
        await tmp.writeAsBytes(file.bytes!);
        if (await tmp.exists()) imageFile = tmp;
      }

      if (imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao acessar imagem.'), backgroundColor: AppTheme.errorColor),
        );
        return;
      }

      setState(() => _uploadingCover = true);
      final themeKey = _themeKeyController.text.trim();
      final url = await ThemeService.instance.uploadThemeImage(imageFile, themeKey: themeKey.isNotEmpty ? themeKey : null);
      setState(() => _uploadingCover = false);

      if (url != null && mounted) {
        setState(() {
          _coverImageUrlController.text = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capa enviada com sucesso!')));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao fazer upload da capa.'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    } catch (e) {
      setState(() => _uploadingCover = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _uploadPreviewImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      File? imageFile;

      // Tentar usar path primeiro
      if (file.path != null && file.path!.isNotEmpty) {
        var pathStr = file.path!;
        if (pathStr.startsWith('file://')) pathStr = pathStr.substring(7);
        final f = File(pathStr);
        if (await f.exists()) imageFile = f;
      }

      // Fallback: usar bytes
      if (imageFile == null && file.bytes != null && file.bytes!.isNotEmpty) {
        final dir = await getTemporaryDirectory();
        final ext = file.extension ?? 'jpg';
        final tmp = File('${dir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.$ext');
        await tmp.writeAsBytes(file.bytes!);
        if (await tmp.exists()) imageFile = tmp;
      }

      if (imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao acessar imagem.'), backgroundColor: AppTheme.errorColor),
        );
        return;
      }

      setState(() => _uploadingPreview = true);
      final themeKey = _themeKeyController.text.trim();
      final url = await ThemeService.instance.uploadThemeImage(imageFile, themeKey: themeKey.isNotEmpty ? themeKey : null);
      setState(() => _uploadingPreview = false);

      if (url != null && mounted) {
        setState(() {
          _previewImageUrlController.text = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preview enviado com sucesso!')));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao fazer upload do preview.'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    } catch (e) {
      setState(() => _uploadingPreview = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _uploadMusic() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      File? musicFile;

      // Tentar usar path primeiro
      if (file.path != null && file.path!.isNotEmpty) {
        var pathStr = file.path!;
        if (pathStr.startsWith('file://')) pathStr = pathStr.substring(7);
        final f = File(pathStr);
        if (await f.exists()) musicFile = f;
      }

      // Fallback: usar bytes
      if (musicFile == null && file.bytes != null && file.bytes!.isNotEmpty) {
        final dir = await getTemporaryDirectory();
        final tmp = File('${dir.path}/music_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await tmp.writeAsBytes(file.bytes!);
        if (await tmp.exists()) musicFile = tmp;
      }

      if (musicFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao acessar arquivo MP3.'), backgroundColor: AppTheme.errorColor),
        );
        return;
      }

      setState(() => _uploadingMusic = true);
      final themeKey = _themeKeyController.text.trim();
      final url = await ThemeService.instance.uploadThemeMusic(musicFile, themeKey: themeKey.isNotEmpty ? themeKey : null);
      setState(() => _uploadingMusic = false);

      if (url != null && mounted) {
        setState(() {
          _backgroundMusicUrlController.text = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Música enviada com sucesso!')));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao fazer upload da música. Certifique-se de que é um arquivo MP3.'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    } catch (e) {
      setState(() => _uploadingMusic = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome obrigatório.'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    final themeKey = _themeKeyController.text.trim();
    if (themeKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Theme Key obrigatório.'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final theme = widget.theme?.copyWith(
            name: name,
            themeKey: themeKey,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            coverImageUrl: _coverImageUrlController.text.trim().isEmpty ? null : _coverImageUrlController.text.trim(),
            backgroundMusicUrl: _backgroundMusicUrlController.text.trim().isEmpty ? null : _backgroundMusicUrlController.text.trim(),
            primaryColor: _primaryColorController.text.trim().isEmpty ? null : _primaryColorController.text.trim(),
            secondaryColor: _secondaryColorController.text.trim().isEmpty ? null : _secondaryColorController.text.trim(),
            previewImageUrl: _previewImageUrlController.text.trim().isEmpty ? null : _previewImageUrlController.text.trim(),
            active: _active,
            buttonStyle: _buttonStyle,
            decorativeElements: _decorativeElements,
          ) ??
          ProfileTheme(
            id: '',
            themeKey: themeKey,
            name: name,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            coverImageUrl: _coverImageUrlController.text.trim().isEmpty ? null : _coverImageUrlController.text.trim(),
            backgroundMusicUrl: _backgroundMusicUrlController.text.trim().isEmpty ? null : _backgroundMusicUrlController.text.trim(),
            primaryColor: _primaryColorController.text.trim().isEmpty ? null : _primaryColorController.text.trim(),
            secondaryColor: _secondaryColorController.text.trim().isEmpty ? null : _secondaryColorController.text.trim(),
            previewImageUrl: _previewImageUrlController.text.trim().isEmpty ? null : _previewImageUrlController.text.trim(),
            active: _active,
            buttonStyle: _buttonStyle,
            decorativeElements: _decorativeElements,
          );
      final saved = await ThemeService.instance.upsertThemeForAdmin(theme);
      if (!mounted) return;
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tema salvo.')));
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar.'), backgroundColor: AppTheme.errorColor),
        );
      }
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

    return Dialog(
      backgroundColor: surface,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(widget.theme == null ? 'Novo Tema' : 'Editar Tema'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.preview),
                  tooltip: 'Preview',
                  onPressed: () {
                    final previewTheme = ProfileTheme(
                      id: '',
                      themeKey: _themeKeyController.text.trim(),
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim(),
                      coverImageUrl: _coverImageUrlController.text.trim(),
                      backgroundMusicUrl: _backgroundMusicUrlController.text.trim(),
                      primaryColor: _primaryColorController.text.trim(),
                      secondaryColor: _secondaryColorController.text.trim(),
                      previewImageUrl: _previewImageUrlController.text.trim(),
                      active: _active,
                      buttonStyle: _buttonStyle,
                      decorativeElements: _decorativeElements,
                    );
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (ctx) => _ThemePreviewDialog(theme: previewTheme),
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Presets Temáticos', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kThemePresets.map((preset) {
                        return FilterChip(
                          label: Text(preset.name),
                          selected: _selectedPreset == preset.name,
                          onSelected: (_) => _applyPreset(preset.name),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Tema',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _themeKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Theme Key (ex: stranger_things)',
                        border: OutlineInputBorder(),
                        helperText: 'Identificador único do tema',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    // Capa: Upload ou URL
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _coverImageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'URL da Capa',
                              border: OutlineInputBorder(),
                              helperText: 'Ou faça upload de uma imagem',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _uploadingCover ? null : _uploadCoverImage,
                          icon: _uploadingCover
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.upload_file),
                          label: const Text('Upload'),
                        ),
                      ],
                    ),
                    if (_coverImageUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _coverImageUrlController.text,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(height: 100, child: Icon(Icons.error)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Preview: Upload ou URL
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _previewImageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'URL da Imagem Preview',
                              border: OutlineInputBorder(),
                              helperText: 'Ou faça upload de uma imagem',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _uploadingPreview ? null : _uploadPreviewImage,
                          icon: _uploadingPreview
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.upload_file),
                          label: const Text('Upload'),
                        ),
                      ],
                    ),
                    if (_previewImageUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _previewImageUrlController.text,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(height: 100, child: Icon(Icons.error)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Música: Upload ou URL
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _backgroundMusicUrlController,
                            decoration: const InputDecoration(
                              labelText: 'URL da Música de Fundo (MP3)',
                              border: OutlineInputBorder(),
                              helperText: 'Ou faça upload de um arquivo MP3',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _uploadingMusic ? null : _uploadMusic,
                          icon: _uploadingMusic
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.upload_file),
                          label: const Text('Upload'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _primaryColorController,
                            decoration: const InputDecoration(
                              labelText: 'Cor Primária (hex)',
                              border: OutlineInputBorder(),
                              prefixText: '#',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _secondaryColorController,
                            decoration: const InputDecoration(
                              labelText: 'Cor Secundária (hex)',
                              border: OutlineInputBorder(),
                              prefixText: '#',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Estilo de Botões', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kButtonStyles.entries.map((entry) {
                        return FilterChip(
                          label: Text(entry.key),
                          selected: _buttonStyle?['type'] == entry.key,
                          onSelected: (_) {
                            setState(() {
                              _buttonStyle = Map<String, dynamic>.from(entry.value);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text('Efeitos Decorativos', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kDecorativeEffects.entries.map((entry) {
                        return FilterChip(
                          label: Text(entry.key),
                          selected: _decorativeElements?['particles'] == entry.value['particles'],
                          onSelected: (_) {
                            setState(() {
                              _decorativeElements = Map<String, dynamic>.from(entry.value);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Ativo'),
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Salvar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
