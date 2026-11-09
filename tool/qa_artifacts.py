from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
from zipfile import ZipFile
import json
from lxml import etree
root=Path(__file__).resolve().parents[1]
qa=root/'.tooling'
for prefix, folder, pattern, per in [('report',qa/'report-qa','final-page-*.png',6),('slides',qa/'artifact-qa','slide-*.png',6),('diagrams',root/'docs/diagrams','*.png',6)]:
    files=list(folder.glob(pattern))
    if prefix=='diagrams': files=[p for p in files if not p.stem.endswith('_report')]
    files.sort(key=lambda p:int(p.stem.split('-')[-1]) if prefix=='slides' else p.name)
    for j in range(0,len(files),per):
        sheet=Image.new('RGB',(1600,2400),'#dddddd');d=ImageDraw.Draw(sheet)
        for i,p in enumerate(files[j:j+per]):
            thumb=ImageOps.contain(Image.open(p),(780,750))
            sheet.paste(thumb,((i%2)*800,(i//2)*800));d.text(((i%2)*800+10,(i//2)*800+760),p.name,fill='black')
        sheet.save(qa/f'{prefix}-qa-{j//per+1}.png')
for p in (root/'deliverables').glob('*.pptx'):
    with ZipFile(p) as z:
        bad=[x.filename for x in z.infolist() if x.filename.startswith('ppt/media/') and x.file_size==0]
        assert not bad,bad
        print(p.name,'slides=',sum(x.startswith('ppt/slides/slide') and x.endswith('.xml') for x in z.namelist()),'nonempty media verified')
with ZipFile(root/'deliverables/bao_cao_quan_ly_suc_khoe.docx') as z:
    assert z.testzip() is None
    assert '<w:sz w:val="26"' in z.read('word/styles.xml').decode()
    styles=etree.fromstring(z.read('word/styles.xml'))
    ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
    assert not styles.xpath('//w:style[@w:styleId="Title"]//w:pBdr',namespaces=ns)
    print('DOCX valid package; TNR 13 normal style; no paragraph border')
