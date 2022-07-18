import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/painting_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/text_editing_notifier.dart';
import 'package:stories_editor/src/domain/sevices/save_as_image.dart';
import 'package:stories_editor/src/presentation/utils/Extensions/hexColor.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';

/// custom exit dialog
Future<bool> exitDialog({required context, required contentKey}) async {
  return (await showDialog(
        context: context,
        barrierColor: Colors.black38,
        barrierDismissible: true,
        builder: (c) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Dialog(
              clipBehavior: Clip.hardEdge,
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetAnimationDuration: const Duration(milliseconds: 300),
              insetAnimationCurve: Curves.ease,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  // height: 280,
                  decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: HexColor.fromHex('#262626'),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.white10,
                            offset: Offset(0, 1),
                            blurRadius: 4),
                      ]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Удалить изменения?',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        "Если Вы вернетесь сейчас, совершенные изменения не будут сохранены.kfnsldkfnkdsjfdasjndkajsndkajsndkajnsdkajnsdkjansdn",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white54,
                            letterSpacing: 0.1),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 20,
                      ),

                      /// discard
                      AnimatedOnTapButton(
                        onTap: () async {
                          _resetDefaults(context: context);
                          Navigator.of(context).pop(true);
                        },
                        child: Text(
                          'Вернуться',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.redAccent.shade200,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                        child: Divider(
                          color: Colors.white10,
                        ),
                      ),

                      /// save and exit
                      AnimatedOnTapButton(
                        onTap: () async {
                          final _paintingProvider =
                              Provider.of<PaintingNotifier>(context,
                                  listen: false);
                          final _widgetProvider =
                              Provider.of<DraggableWidgetNotifier>(context,
                                  listen: false);
                          if (_paintingProvider.lines.isNotEmpty ||
                              _widgetProvider.draggableWidget.isNotEmpty) {
                            /// save image
                            var response = await takePicture(
                                contentKey: contentKey,
                                context: context,
                                saveToGallery: true);
                            if (response) {
                              _dispose(context: context, message: 'Сохранено');
                            } else {
                              _dispose(context: context, message: 'Error');
                            }
                          } else {
                            _dispose(
                                context: context, message: 'Пустой черновик');
                          }
                        },
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(
                        height: 18,
                        child: Divider(
                          color: Colors.white10,
                        ),
                      ),

                      ///cancel
                      AnimatedOnTapButton(
                        onTap: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      )) ??
      false;
}

_resetDefaults({required BuildContext context}) {
  final _paintingProvider =
      Provider.of<PaintingNotifier>(context, listen: false);
  final _widgetProvider =
      Provider.of<DraggableWidgetNotifier>(context, listen: false);
  final _controlProvider = Provider.of<ControlNotifier>(context, listen: false);
  final _editingProvider =
      Provider.of<TextEditingNotifier>(context, listen: false);
  _paintingProvider.lines.clear();
  _widgetProvider.draggableWidget.clear();
  _widgetProvider.setDefaults();
  _paintingProvider.resetDefaults();
  _editingProvider.setDefaults();
  _controlProvider.mediaPath = '';
}

_dispose({required context, required message}) {
  _resetDefaults(context: context);
  Fluttertoast.showToast(msg: message);
  Navigator.of(context).pop(true);
}
