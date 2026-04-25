import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../i18n/app_strings.dart';
import '../models/app_update.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import '../services/service_locator.dart';

class UpdateManager {
  static final UpdateManager _instance = UpdateManager._internal();
  factory UpdateManager() => _instance;
  UpdateManager._internal();

  final UpdateService _updateService = UpdateService();
  
  // Android 安装 APK 的 MethodChannel
  static const _installChannel = MethodChannel('com.flutteriptv/install');

  /// 检查更新并显示更新对话框
  Future<void> checkAndShowUpdateDialog(BuildContext context, {bool forceCheck = false}) async {
    try {
      ServiceLocator.log.d('UPDATE_MANAGER: 开始检查更新...');

      final update = await _updateService.checkForUpdates(forceCheck: forceCheck);

      if (update != null && context.mounted) {
        ServiceLocator.log.d('UPDATE_MANAGER: 发现新版本，显示更新对话框');
        _showUpdateDialog(context, update);
      } else {
        ServiceLocator.log.d('UPDATE_MANAGER: 没有发现新版本');
      }
    } catch (e) {
      ServiceLocator.log.d('UPDATE_MANAGER: 检查更新时发生错误: $e');
    }
  }

  /// 手动检查更新
  Future<void> manualCheckForUpdate(BuildContext context) async {
    try {
      ServiceLocator.log.d('UPDATE_MANAGER: 手动检查更新...');

      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(AppStrings.of(context)?.checkingUpdate ?? 'Verificando atualizações...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final update = await _updateService.checkForUpdates(forceCheck: true);

      // 隐藏加载提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (update != null && context.mounted) {
        ServiceLocator.log.d('UPDATE_MANAGER: 发现新版本，显示更新对话框');
        _showUpdateDialog(context, update);
      } else if (context.mounted) {
        ServiceLocator.log.d('UPDATE_MANAGER: 已是最新版本');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context)?.alreadyLatestVersion ?? 'Já está na versão mais recente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ServiceLocator.log.d('UPDATE_MANAGER: 手动检查更新时发生错误: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (AppStrings.of(context)?.checkUpdateFailed ?? 'Falha ao verificar atualização: {error}')
                  .replaceAll('{error}', e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mostra o diálogo de atualização (público para uso na splash ou em outros pontos).
  /// [onDismiss] é chamado quando o utilizador escolhe "Depois" e o diálogo fecha.
  void showUpdateDialog(
    BuildContext context,
    AppUpdate update, {
    void Function()? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(
        update: update,
        onUpdate: () => _handleUpdate(context, update),
        onCancel: () {
          Navigator.of(context).pop();
          ServiceLocator.log.d('UPDATE_MANAGER: 用户选择稍后更新');
          onDismiss?.call();
        },
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, AppUpdate update) {
    showUpdateDialog(context, update);
  }

  /// 处理更新操作
  Future<void> _handleUpdate(BuildContext context, AppUpdate update) async {
    try {
      ServiceLocator.log.d('UPDATE_MANAGER: 用户选择立即更新');

      // 关闭对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (Platform.isAndroid) {
        await _downloadAndInstallAndroid(context, update);
      } else if (Platform.isWindows) {
        await _downloadAndInstallWindows(context, update);
      } else {
        // 其他平台打开下载页面
        await _updateService.openDownloadPage();
      }
    } catch (e) {
      ServiceLocator.log.d('UPDATE_MANAGER: 处理更新时发生错误: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (AppStrings.of(context)?.updateFailed ?? 'Falha na atualização: {error}')
                  .replaceAll('{error}', e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Android 下载并安装 APK
  Future<void> _downloadAndInstallAndroid(BuildContext context, AppUpdate update) async {
    double progress = 0;
    bool cancelled = false;
    void Function(void Function())? dialogSetState;
    BuildContext? dialogContext;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;
            return AlertDialog(
              title: Text(AppStrings.of(context)?.downloadUpdate ?? 'Baixar atualização'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 16),
                  Text('${(progress * 100).toStringAsFixed(1)}%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cancelled = true;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(AppStrings.of(context)?.cancel ?? 'Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      final file = await _updateService.downloadUpdate(
        update,
        onProgress: (p) {
          if (!cancelled && dialogSetState != null) {
            progress = p;
            dialogSetState!(() {});
          }
        },
      );

      if (cancelled) {
        ServiceLocator.log.d('UPDATE_MANAGER: 用户取消下载');
        // 删除未完成的下载文件
        if (file != null && await file.exists()) {
          await file.delete();
        }
        return;
      }

      // 关闭下载对话框
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      if (file != null) {
        ServiceLocator.log.d('UPDATE_MANAGER: 下载完成，开始安装: ${file.path}');
        try {
          await _installApk(file.path);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.of(context)?.installerOpened ?? 'Instalador aberto. Confirme a instalação para concluir a atualização.'),
                duration: const Duration(seconds: 6),
              ),
            );
          }
        } catch (installError) {
          // Erro específico de instalação - mostra mensagem mais clara
          if (dialogContext != null && dialogContext!.mounted) {
            Navigator.of(dialogContext!).pop();
          }
          if (context.mounted) {
            final errorMsg = installError.toString();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg.contains('Conflito') || errorMsg.contains('conflito')
                    ? errorMsg
                    : 'Falha na instalação: $installError'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      } else {
        throw Exception('Falha no download');
      }
    } catch (e) {
      ServiceLocator.log.d('UPDATE_MANAGER: 下载失败: $e');
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha no download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 调用原生方法安装 APK
  Future<void> _installApk(String filePath) async {
    try {
      await _installChannel.invokeMethod('installApk', {'filePath': filePath});
    } catch (e) {
      ServiceLocator.log.d('UPDATE_MANAGER: 安装 APK 失败: $e');
      // Se o erro for de conflito de instalação, fornece mensagem mais clara
      final errorMsg = e.toString();
      if (errorMsg.contains('INSTALL_FAILED_UPDATE_INCOMPATIBLE') || 
          errorMsg.contains('INSTALL_FAILED_ALREADY_EXISTS') ||
          errorMsg.contains('conflict') ||
          errorMsg.contains('conflito')) {
        throw Exception('Conflito de instalação detectado. Por favor, desinstale a versão antiga manualmente e tente novamente.');
      }
      rethrow;
    }
  }

  /// Windows 下载并安装
  Future<void> _downloadAndInstallWindows(BuildContext context, AppUpdate update) async {
    double progress = 0;
    bool cancelled = false;
    bool dialogOpen = true;
    void Function(void Function())? dialogSetState;
    final navigatorState = Navigator.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setState) {
            dialogSetState = setState;
            return AlertDialog(
              title: Text(AppStrings.of(context)?.downloadUpdate ?? 'Baixar atualização'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 16),
                  Text('${(progress * 100).toStringAsFixed(1)}%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cancelled = true;
                    dialogOpen = false;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(AppStrings.of(context)?.cancel ?? 'Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      final file = await _updateService.downloadUpdate(
        update,
        onProgress: (p) {
          if (!cancelled && dialogSetState != null) {
            progress = p;
            dialogSetState!(() {});
          }
        },
      );

      if (cancelled) {
        ServiceLocator.log.d('UPDATE_MANAGER: 用户取消下载');
        // 删除未完成的下载文件
        if (file != null && await file.exists()) {
          await file.delete();
          ServiceLocator.log.d('UPDATE_MANAGER: 已删除未完成的下载文件');
        }
        return;
      }

      // 关闭下载对话框
      if (dialogOpen) {
        dialogOpen = false;
        navigatorState.pop();
      }

      ServiceLocator.log.d('UPDATE_MANAGER: 对话框已关闭，file=${file?.path}');

      if (file != null) {
        ServiceLocator.log.d('UPDATE_MANAGER: 下载完成: ${file.path}');
        
        // Windows: 启动安装程序
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(AppStrings.of(context)?.downloadComplete ?? 'Download concluído'),
              content: Text(AppStrings.of(context)?.runInstallerNow ?? 'Executar instalador agora?'),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    // 用户选择稍后，删除下载文件
                    try {
                      if (await file.exists()) {
                        await file.delete();
                        ServiceLocator.log.d('UPDATE_MANAGER: 已删除下载文件');
                      }
                    } catch (e) {
                      ServiceLocator.log.d('UPDATE_MANAGER: 删除文件失败: $e');
                    }
                  },
                  child: Text(AppStrings.of(context)?.later ?? 'Mais tarde'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    ServiceLocator.log.d('UPDATE_MANAGER: 启动安装程序: ${file.path}');
                    // 启动安装程序
                    await Process.start(file.path, [], mode: ProcessStartMode.detached);
                    // 退出当前应用
                    exit(0);
                  },
                  child: Text(AppStrings.of(context)?.installNow ?? 'Instalar agora'),
                ),
              ],
            ),
          );
        } else {
          ServiceLocator.log.d('UPDATE_MANAGER: context not mounted, 直接启动安装');
          await Process.start(file.path, [], mode: ProcessStartMode.detached);
          exit(0);
        }
      } else {
        throw Exception('Falha no download');
      }
    } catch (e) {
      ServiceLocator.log.d('UPDATE_MANAGER: 下载失败: $e');
      if (dialogOpen) {
        dialogOpen = false;
        navigatorState.pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha no download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 获取当前应用版本
  Future<String> getCurrentVersion() async {
    try {
      return await _updateService.getCurrentVersion();
    } catch (e) {
      ServiceLocator.log.d('UPDATE_MANAGER: 获取当前版本失败: $e');
      return '0.0.0';
    }
  }
}
