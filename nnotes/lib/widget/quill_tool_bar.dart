import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';


class quillToolBar extends StatelessWidget {
  const quillToolBar({
    super.key,
    required QuillController quillController,
  }) : _quillController = quillController;

  final QuillController _quillController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //show toolbar for the first column
        QuillSimpleToolbar(
          configurations: QuillSimpleToolbarConfigurations(
            controller: _quillController,
            // Icon will Appear
            showBoldButton: true,
            showItalicButton: true,
            showStrikeThrough: true,
            showClearFormat: true,
            showSubscript: true,
            showSuperscript: true,
            showFontFamily: true,
            showFontSize: true,
            showColorButton: true,
            showBackgroundColorButton: true,
            showUnderLineButton: true,

            // Icon Will Desapear
            showInlineCode: false,
            showLineHeightButton: false,
            showAlignmentButtons: false,
            showHeaderStyle: false,
            showListNumbers: false,
            showListBullets: false,
            showListCheck: false,
            showCodeBlock: false,
            showQuote: false,
            showIndent: false,
            showLink: false,
            showUndo: false,
            showRedo: false,
            showDirection: false,
            showSearchButton: false,
            showClipboardCut: false,
            showClipboardCopy: false,
            showClipboardPaste: false,
            multiRowsDisplay: false,
            showCenterAlignment: false,
            showDividers: false,
            showJustifyAlignment: false,
            showLeftAlignment: false,
            showRightAlignment: false,
            showSmallButton: false,
          ),
        ),

        // 🅱️ Paragraph Style
        QuillSimpleToolbar(
          configurations: QuillSimpleToolbarConfigurations(
              controller: _quillController,
              showHeaderStyle: true,
              showQuote: true,
              showCodeBlock: true,
              showListNumbers: true,
              showListBullets: true,
              showListCheck: true,
              showLineHeightButton: true,
              showIndent: true,

              // Others false
              showBoldButton: false,
              showItalicButton: false,
              showStrikeThrough: false,
              showInlineCode: false,
              showClearFormat: false,
              showSubscript: false,
              showSuperscript: false,
              showFontFamily: false,
              showFontSize: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showAlignmentButtons: false,
              showLink: false,
              showUndo: false,
              showRedo: false,
              showDirection: false,
              showSearchButton: false,
              showClipboardCut: false,
              showClipboardCopy: false,
              showClipboardPaste: false,
              multiRowsDisplay: false,
              showCenterAlignment: false,
              showJustifyAlignment: false,
              showDividers: false,
              showLeftAlignment: false,
              showRightAlignment: false,
              showSmallButton: false,
              showUnderLineButton: false),
        ),

        // 🔤 Alignment
        QuillSimpleToolbar(
          configurations: QuillSimpleToolbarConfigurations(
            controller: _quillController,
            showAlignmentButtons: true,
            showDirection: true,

            // Others false
            showUnderLineButton: false,
            showDividers: false,
            showBoldButton: false,
            showItalicButton: false,
            showStrikeThrough: false,
            showInlineCode: false,
            showClearFormat: false,
            showSubscript: false,
            showSuperscript: false,
            showFontFamily: false,
            showFontSize: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            showHeaderStyle: false,
            showQuote: false,
            showCodeBlock: false,
            showListNumbers: false,
            showListBullets: false,
            showListCheck: false,
            showLineHeightButton: false,
            showIndent: false,
            showLink: false,
            showUndo: false,
            showRedo: false,
            showSearchButton: false,
            showClipboardCut: false,
            showClipboardCopy: false,
            showClipboardPaste: false,
            multiRowsDisplay: false,
          ),
        ),

        // 🔗 Link & Clipboard
        QuillSimpleToolbar(
          configurations: QuillSimpleToolbarConfigurations(
            controller: _quillController,
            showLink: true,
            showClipboardCut: true,
            showClipboardCopy: true,
            showClipboardPaste: true,
            showUndo: true,
            showRedo: true,
            showSearchButton: true,

            // Others false
            showDividers: false,
            showUnderLineButton: false,
            showBoldButton: false,
            showItalicButton: false,
            showStrikeThrough: false,
            showInlineCode: false,
            showClearFormat: false,
            showSubscript: false,
            showSuperscript: false,
            showFontFamily: false,
            showFontSize: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            showHeaderStyle: false,
            showQuote: false,
            showCodeBlock: false,
            showListNumbers: false,
            showListBullets: false,
            showListCheck: false,
            showLineHeightButton: false,
            showIndent: false,
            showAlignmentButtons: false,
            showDirection: false,
            multiRowsDisplay: false,
          ),
        ),
      ],
    );
  }
}
