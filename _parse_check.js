const fs=require('fs');
const src=fs.readFileSync('script.js','utf8');
new Function(src);
console.log('PARSE_OK');
