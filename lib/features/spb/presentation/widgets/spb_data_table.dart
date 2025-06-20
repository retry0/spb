import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/spb_bloc.dart';
import '../../data/models/spb_model.dart';
import 'spb_search_bar.dart';
import 'spb_pagination_controls.dart';
import 'spb_offline_indicator.dart';

class SpbDataTable extends StatefulWidget {
  const SpbDataTable({super.key});

  @override
  State<SpbDataTable> createState() => _SpbDataTableState();
}

class _SpbDataTableState extends State<SpbDataTable> {
  final RefreshController _refreshController = RefreshController();
  String? _driver;
  String? _kdVendor;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _getUserInfo() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      setState(() {
        _driver = authState.user.UserName;
        _kdVendor = authState.user.Id;
      });
      
      // Load data once we have user info
      if (_driver != null && _kdVendor != null) {
        context.read<SpbBloc>().add(SpbLoadRequested(
          driver: _driver!,
          kdVendor: _kdVendor!,
        ));
      }
    }
  }

  void _onRefresh() {
    if (_driver != null && _kdVendor != null) {
      context.read<SpbBloc>().add(SpbRefreshRequested(
        driver: _driver!,
        kdVendor: _kdVendor!,
      ));
    }
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SpbBloc, SpbState>(
      listener: (context, state) {
        if (state is SpbLoadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is SpbSyncFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // Offline indicator
            if (state is SpbLoaded && !state.isConnected)
              const SpbOfflineIndicator(),
              
            // Search bar
            SpbSearchBar(
              onSearch: (query) {
                context.read<SpbBloc>().add(SpbSearchRequested(query: query));
              },
              searchQuery: state is SpbLoaded ? state.searchQuery : '',
            ),
            
            // Data table
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                child: _buildTableContent(context, state),
              ),
            ),
            
            // Pagination controls
            if (state is SpbLoaded)
              SpbPaginationControls(
                currentPage: state.currentPage,
                totalPages: state.totalPages,
                onPageChanged: (page) {
                  context.read<SpbBloc>().add(SpbPageChanged(page: page));
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildTableContent(BuildContext context, SpbState state) {
    if (state is SpbLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is SpbLoaded || state is SpbRefreshing || state is SpbSyncing) {
      List<SpbModel> spbList;
      bool isRefreshing = false;
      
      if (state is SpbLoaded) {
        spbList = state.spbList;
      } else if (state is SpbRefreshing) {
        spbList = state.spbList;
        isRefreshing = true;
      } else if (state is SpbSyncing) {
        spbList = (state as SpbSyncing).spbList;
        isRefreshing = true;
      } else if (state is SpbSyncFailure) {
        spbList = state.spbList;
      } else {
        spbList = [];
      }
      
      if (spbList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No SPB data available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }
      
      return Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: _buildColumns(context, state),
                rows: _buildRows(context, spbList),
                sortColumnIndex: _getSortColumnIndex(state),
                sortAscending: state is SpbLoaded ? state.sortAscending : false,
                showCheckboxColumn: false,
                horizontalMargin: 16,
                columnSpacing: 16,
              ),
            ),
          ),
          if (isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
        ],
      );
    } else if (state is SpbLoadFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load SPB data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_driver != null && _kdVendor != null) {
                  context.read<SpbBloc>().add(SpbLoadRequested(
                    driver: _driver!,
                    kdVendor: _kdVendor!,
                  ));
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  List<DataColumn> _buildColumns(BuildContext context, SpbState state) {
    return [
      DataColumn(
        label: const Text('No. SPB'),
        onSort: (columnIndex, ascending) {
          context.read<SpbBloc>().add(SpbSortRequested(
            column: 'noSpb',
            ascending: ascending,
          ));
        },
      ),
      DataColumn(
        label: const Text('Tanggal Antar Buah'),
        onSort: (columnIndex, ascending) {
          context.read<SpbBloc>().add(SpbSortRequested(
            column: 'tglAntarBuah',
            ascending: ascending,
          ));
        },
      ),
      DataColumn(
        label: const Text('Mill Tujuan'),
        onSort: (columnIndex, ascending) {
          context.read<SpbBloc>().add(SpbSortRequested(
            column: 'millTujuan',
            ascending: ascending,
          ));
        },
      ),
      DataColumn(
        label: const Text('Status'),
        onSort: (columnIndex, ascending) {
          context.read<SpbBloc>().add(SpbSortRequested(
            column: 'status',
            ascending: ascending,
          ));
        },
      ),
    ];
  }

  List<DataRow> _buildRows(BuildContext context, List<SpbModel> spbList) {
    return spbList.map((spb) {
      return DataRow(
        cells: [
          DataCell(Text(spb.noSpb)),
          DataCell(Text(spb.tglAntarBuah)),
          DataCell(Text(spb.millTujuan)),
          DataCell(_buildStatusCell(context, spb.status)),
        ],
        onSelectChanged: (selected) {
          if (selected == true) {
            _showSpbDetails(context, spb);
          }
        },
      );
    }).toList();
  }

  Widget _buildStatusCell(BuildContext context, String status) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'selesai':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'proses':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'batal':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, color: statusColor, size: 16),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(color: statusColor),
        ),
      ],
    );
  }

  void _showSpbDetails(BuildContext context, SpbModel spb) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('SPB Detail: ${spb.noSpb}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('No. SPB', spb.noSpb),
              _buildDetailRow('Tanggal Antar Buah', spb.tglAntarBuah),
              _buildDetailRow('Mill Tujuan', spb.millTujuan),
              _buildDetailRow('Status', spb.status),
              if (spb.keterangan != null && spb.keterangan!.isNotEmpty)
                _buildDetailRow('Keterangan', spb.keterangan!),
              if (spb.createdAt != null)
                _buildDetailRow(
                  'Created At',
                  DateFormat('dd/MM/yyyy HH:mm').format(spb.createdAt!),
                ),
              _buildDetailRow('Synced', spb.isSynced ? 'Yes' : 'No'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  int? _getSortColumnIndex(SpbState state) {
    if (state is SpbLoaded) {
      switch (state.sortColumn) {
        case 'noSpb':
          return 0;
        case 'tglAntarBuah':
          return 1;
        case 'millTujuan':
          return 2;
        case 'status':
          return 3;
        default:
          return 1; // Default to tglAntarBuah
      }
    }
    return null;
  }
}