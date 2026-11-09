import fs from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import Module,{createRequire} from 'node:module';
const runtime='C:/Users/phitr/.cache/codex-runtimes/codex-primary-runtime/dependencies';
// Runtime package misses its PDF standard-font aliases. Supply official AFM
// metrics from the bundled pdf-lib package without modifying managed files.
const req=createRequire(`${runtime}/node/node_modules/package.json`);
const {Font}=req('@pdf-lib/standard-fonts');
const originalLoad=Module._load;
Module._load=function(id,...args){
 if(typeof id==='string' && id.startsWith('#standard-fonts/')){
  const raw=id.slice('#standard-fonts/'.length);
  const name=raw.replace(/(Helvetica|Courier|Times)(BoldOblique|BoldItalic|Bold|Oblique|Italic|Roman)/,'$1-$2');
  const f=Font.load(name);return {name,bbox:f.FontBBox,ascender:f.Ascender??700,descender:f.Descender??-200,xHeight:f.XHeight??450,capHeight:f.CapHeight??700,glyphNames:f.CharMetrics.map(x=>x.N).join(' '),glyphWidths:f.CharMetrics.map(x=>x.WX),kernPairs:[]};
 }
 return originalLoad.call(this,id,...args);
};
const {DocumentFile,registerPdfFontFace}=await import(pathToFileURL(`${runtime}/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs`).href);
for(const [file,weight,style] of [['times.ttf',400,'normal'],['timesbd.ttf',700,'normal'],['timesi.ttf',400,'italic'],['timesbi.ttf',700,'italic']]){
 registerPdfFontFace({family:'Times New Roman',source:new Uint8Array(await fs.readFile(`C:/Windows/Fonts/${file}`)),weight,style});
}
const model=await DocumentFile.importDocx(new Uint8Array(await fs.readFile('deliverables/bao_cao_quan_ly_suc_khoe.docx')));
const pdf=await model.export({format:'pdf'});
await fs.mkdir('.tooling/report-qa',{recursive:true});
await fs.writeFile('.tooling/report-qa/report.pdf',pdf instanceof Uint8Array?pdf:new Uint8Array(await pdf.arrayBuffer()));
console.log('Rendered actual DOCX through DocumentFile import/export');
