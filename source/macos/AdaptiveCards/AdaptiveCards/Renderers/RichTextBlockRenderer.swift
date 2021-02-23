import AdaptiveCards_bridge
import AppKit

class RichTextBlockRenderer: NSObject, BaseCardElementRendererProtocol {
    static let shared = RichTextBlockRenderer()
    
    func render(element: ACSBaseCardElement, with hostConfig: ACSHostConfig, style: ACSContainerStyle, rootView: NSView, parentView: NSView, inputs: [BaseInputHandler]) -> NSView {
        guard let richTextBlock = element as? ACSRichTextBlock else {
            logError("Element is not of type ACSRichTextBlock")
            return NSView()
        }
        
        let textView = ACRTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.layoutManager?.usesFontLeading = false
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.backgroundColor = .clear
        
        // init content
        let content = NSMutableAttributedString()
        
        // parsing through the inlines
        for inline in richTextBlock.getInlines() {
            let textRun = inline as? ACSTextRun

            if textRun != nil {
                let textRunContent: NSMutableAttributedString
                
                let markdownResult = BridgeTextUtils.processText(fromRichTextBlock: textRun, hostConfig: hostConfig)
                if markdownResult.isHTML, let htmlData = markdownResult.htmlData {
                    do {
                        textRunContent = try NSMutableAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                        // Delete trailing newline character
                        textRunContent.deleteCharacters(in: NSRange(location: textRunContent.length - 1, length: 1))
                        textView.isSelectable = true
                    } catch {
                        textRunContent = NSMutableAttributedString(string: markdownResult.parsedString)
                    }
                } else {
                    textRunContent = NSMutableAttributedString(string: markdownResult.parsedString)
                    // Delete <p> and </p>
                    textRunContent.deleteCharacters(in: NSRange(location: 0, length: 3))
                    textRunContent.deleteCharacters(in: NSRange(location: textRunContent.length - 4, length: 4))
                }
                
                // Set paragraph style such as line break mode and alignment
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = ACSHostConfig.getTextBlockAlignment(from: richTextBlock.getHorizontalAlignment())
                textRunContent.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: textRunContent.length))

                // Obtain text color to apply to the attributed string
                if let colorHex = hostConfig.getForegroundColor(style, color: textRun?.getTextColor() ?? ACSForegroundColor.default, isSubtle: textRun?.getIsSubtle() ?? false) {
                    let foregroundColor = ColorUtils.color(from: colorHex) ?? NSColor.darkGray
                    textRunContent.addAttributes([.foregroundColor: foregroundColor], range: NSRange(location: 0, length: textRunContent.length))
                }
                
                // NEED TO IMPLEMENT - IN PROGRESS
//                // apply highlight to textrun
//                if textRun?.getHighlight() ?? false {
//                    if let colorHex = hostConfig.getHighlightColor(style, color: textRun?.getTextColor() ?? ACSForegroundColor.default, isSubtle: textRun?.getIsSubtle() ?? false) {
//                         let highlightColor = ColorUtils.color(from: colorHex)
//                        textRunContent.addAttributes([.backgroundColor: NSColor.], range: NSRange(location: 0, length: textRunContent.length))
//                    }
//                }
                
                // apply strikethrough to textrun
                if textRun?.getStrikethrough() ?? false {
                    textRunContent.addAttributes([.strikethroughStyle: 1], range: NSRange(location: 0, length: textRunContent.length))
                }
                    
                // apply underline to textrun
                if textRun?.getUnderline() ?? false {
                    textRunContent.addAttributes([.underlineStyle: NSUnderlineStyle.single.rawValue], range: NSRange(location: 0, length: textRunContent.length))
                }
                content.append(textRunContent)
            }
        }
 
        textView.textContainer?.lineBreakMode = .byTruncatingTail
        textView.textStorage?.setAttributedString(content)
        textView.textContainer?.widthTracksTextView = true
   
        return textView
    }
}
