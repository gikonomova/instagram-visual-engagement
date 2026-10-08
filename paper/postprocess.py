"""Apply CSIR journal styles to a pandoc-built .docx in place.

Pandoc writes its own style names (Heading1, BodyText, ...). The CSIR template uses CSIR* styles
and a one-column front matter followed by a two-column body. Usage: postprocess.py paper.docx
"""
import re
import shutil
import sys
import zipfile

STYLES = {"Heading1": "CSIRMainSection", "Heading2": "CSIRSubSection",
          "Heading3": "CSIRSub-Subsection", "BodyText": "CSIRText", "FirstParagraph": "CSIRText",
          "Compact": "CSIRText", "Title": "CSIRTitle", "ImageCaption": "CSIRCaptionFigure",
          "TableCaption": "CSIRTableCaption", "Bibliography": "CSIRReferences"}
TWO_COL = ('<w:sectPr><w:type w:val="continuous"/><w:pgSz w:w="11907" w:h="16839" w:code="9"/>'
           '<w:pgMar w:top="1134" w:right="1021" w:bottom="1134" w:left="1134" w:header="720" '
           'w:footer="720" w:gutter="0"/><w:cols w:num="2" w:space="284"/><w:docGrid w:linePitch="360"/>'
           '</w:sectPr>')


def fix(xml):
    xml = re.sub(r'<w:pStyle w:val="([^"]+)" ?/>',
                 lambda m: f'<w:pStyle w:val="{STYLES.get(m[1], m[1])}"/>', xml)
    # The final sectPr carries the journal headers (one column). It becomes the break after the
    # keywords paragraph, and the body gets a continuous two-column section.
    final = re.findall(r"<w:sectPr\b.*?</w:sectPr>", xml, flags=re.S)[-1]
    xml = xml[: xml.rindex(final)] + TWO_COL + xml[xml.rindex(final) + len(final):]
    kw = xml.rindex('<w:pStyle w:val="CSIRkeywords"/>')
    end = xml.index("</w:p>", kw) + len("</w:p>")
    return xml[:end] + f"<w:p><w:pPr>{final}</w:pPr></w:p>" + xml[end:]


def main(path):
    tmp = path + ".tmp"
    with zipfile.ZipFile(path) as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for it in zin.infolist():
            data = zin.read(it.filename)
            if it.filename == "word/document.xml":
                data = fix(data.decode()).encode()
            zout.writestr(it, data)
    shutil.move(tmp, path)


if __name__ == "__main__":
    main(sys.argv[1])
