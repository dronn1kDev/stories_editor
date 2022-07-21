import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/models/editable_items.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/painting_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/scroll_notifier.dart';
import 'package:stories_editor/src/domain/sevices/save_as_image.dart';
import 'package:stories_editor/src/presentation/utils/constants/item_type.dart';
import 'package:stories_editor/src/presentation/utils/constants/text_animation_type.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class BottomTools extends StatelessWidget {
  final GlobalKey contentKey;
  final Future<void> Function(String imageUri) onDone;
  final Widget? onDoneButtonStyle;
  final Widget? onDoneButtonStyleWhenBuilding;
  final Function renderWidget;

  /// editor background color
  final Color? editorBackgroundColor;
  const BottomTools(
      {Key? key,
      required this.contentKey,
      required this.onDone,
      required this.renderWidget,
      this.onDoneButtonStyle,
      this.onDoneButtonStyleWhenBuilding,
      this.editorBackgroundColor})
      : super(key: key);

  Widget get doneButtonStyle =>
      onDoneButtonStyle ??
      Container(
        padding: const EdgeInsets.only(left: 12, right: 5, top: 4, bottom: 4),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white, width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          Text(
            'Share',
            style: TextStyle(
                color: Colors.white,
                letterSpacing: 1.5,
                fontSize: 16,
                fontWeight: FontWeight.w400),
          ),
          Padding(
            padding: EdgeInsets.only(left: 5),
            child: Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 15,
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    var _size = MediaQuery.of(context).size;
    bool _createVideo = false;
    return Consumer4<ControlNotifier, ScrollNotifier, DraggableWidgetNotifier,
        PaintingNotifier>(
      builder: (_, controlNotifier, scrollNotifier, itemNotifier,
          paintingNotifier, __) {
        return Container(
          height: 95,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// preview gallery
              Container(
                width: _size.width / 3,
                height: _size.width / 3,
                padding: const EdgeInsets.only(left: 15),
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  child: _preViewContainer(
                    /// if [model.imagePath] is null/empty return preview image
                    child: controlNotifier.mediaPath.isEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: GestureDetector(
                              onTap: () async {
                                /// scroll to gridView page
                                if (controlNotifier.mediaPath.isEmpty) {
                                  final files =
                                      await AssetPicker.pickAssets(context,
                                          pickerConfig: const AssetPickerConfig(
                                            maxAssets: 1,
                                            requestType: RequestType.image,
                                          ));
                                  if (files != null && files.isNotEmpty) {
                                    controlNotifier.mediaPath =
                                        (await files.first.file)?.path ?? '';
                                    itemNotifier.draggableWidget.insert(
                                        0,
                                        EditableItem()
                                          ..type = ItemType.image
                                          ..position = const Offset(0.0, 0));
                                  }
                                }
                              },
                              child: const Icon(
                                Icons.photo,
                                color: Colors.white,
                              ),
                            ))

                        /// return clear [imagePath] provider
                        : GestureDetector(
                            onTap: () {
                              /// clear image url variable
                              controlNotifier.mediaPath = '';
                              itemNotifier.draggableWidget.removeAt(0);
                            },
                            child: Container(
                              height: 45,
                              width: 45,
                              color: Colors.transparent,
                              child: Transform.scale(
                                scale: 0.7,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              /// center logo
              controlNotifier.middleBottomWidget != null
                  ? Center(
                      child: Container(
                          width: _size.width / 3,
                          height: 80,
                          alignment: Alignment.bottomCenter,
                          child: controlNotifier.middleBottomWidget),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/instagram_logo.png',
                            package: 'stories_editor',
                            color: Colors.white,
                            height: 42,
                          ),
                          const Text(
                            'Stories Creator',
                            style: TextStyle(
                                color: Colors.white38,
                                letterSpacing: 1.5,
                                fontSize: 9.2,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

              /// save final image to gallery
              Container(
                width: _size.width / 3,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 15),
                child: Transform.scale(
                  scale: 0.9,
                  child: StatefulBuilder(
                    builder: (_, setState) {
                      return AnimatedOnTapButton(
                        onTap: () async {
                          if (controlNotifier.isImageBuilding) {
                            return;
                          } else {
                            controlNotifier.isImageBuilding = true;
                          }
                          String pngUri;
                          if (paintingNotifier.lines.isNotEmpty ||
                              itemNotifier.draggableWidget.isNotEmpty) {
                            for (var element in itemNotifier.draggableWidget) {
                              if (element.animationType !=
                                  TextAnimationType.none) {
                                setState(() {
                                  _createVideo = true;
                                });
                              }
                            }
                            if (_createVideo) {
                              debugPrint('creating video');
                              await renderWidget();
                            } else {
                              debugPrint('creating image');
                              final bytes = await takePicture(
                                  contentKey: contentKey,
                                  context: context,
                                  saveToGallery: false);
                              if (bytes != null) {
                                pngUri = bytes;
                                await onDone(pngUri);
                              }
                            }
                          }
                          setState(() {
                            _createVideo = false;
                          });
                          controlNotifier.isImageBuilding = false;
                        },
                        child: !controlNotifier.isImageBuilding
                            ? doneButtonStyle
                            : onDoneButtonStyleWhenBuilding ?? doneButtonStyle,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _preViewContainer({child}) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1.4, color: Colors.white)),
      child: child,
    );
  }
}
